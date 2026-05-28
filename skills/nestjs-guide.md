# Reference: nestjs-guide
# Load this file when working on tasks matching this domain.

## 🦅 NestJS

### Setup & Tooling
- NestJS 10+ with TypeScript strict mode — always.
- Bootstrap: `pnpm add -g @nestjs/cli && nest new project-name`.
- Package manager: `pnpm` preferred.
- Linting: ESLint with `@nestjs/eslint-config`; formatting: Prettier.
- Run `pnpm lint && tsc --noEmit` before finishing any task.

### Project Structure
```
src/
├── app.module.ts              # Root module
├── main.ts                    # Bootstrap (pipes, guards, interceptors global setup)
├── common/
│   ├── decorators/            # Custom decorators
│   ├── filters/               # Exception filters
│   ├── guards/                # Auth guards
│   ├── interceptors/          # Logging, transform interceptors
│   └── pipes/                 # Validation pipes
├── config/                    # ConfigModule setup
└── modules/
    └── users/
        ├── users.module.ts
        ├── users.controller.ts
        ├── users.service.ts
        ├── users.repository.ts   # optional — data access
        ├── dto/
        │   ├── create-user.dto.ts
        │   └── update-user.dto.ts
        └── entities/
            └── user.entity.ts
```

### Core Principles
- **One module per domain** — `UsersModule`, `AuthModule`, `OrdersModule`.
- Controllers thin — delegate all logic to Services.
- Services handle business logic; Repositories handle data access.
- DTOs for all request/response — never expose entities directly.
- Use `@nestjs/config` (`ConfigModule`) for all env vars — never `process.env` inline.
- Register `ValidationPipe` globally in `main.ts`:

```ts
// main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // strip unknown properties
      forbidNonWhitelisted: true,
      transform: true,        // auto-transform payloads to DTO classes
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.setGlobalPrefix("api/v1");
  await app.listen(3000);
}
```

### Controllers
```ts
@Controller("users")
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll(@Query() query: PaginationDto): Promise<User[]> {
    return this.usersService.findAll(query);
  }

  @Get(":id")
  findOne(@Param("id", ParseIntPipe) id: number): Promise<User> {
    return this.usersService.findOneOrFail(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateUserDto): Promise<User> {
    return this.usersService.create(dto);
  }

  @Patch(":id")
  update(@Param("id", ParseIntPipe) id: number, @Body() dto: UpdateUserDto) {
    return this.usersService.update(id, dto);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param("id", ParseIntPipe) id: number) {
    return this.usersService.remove(id);
  }
}
```

### DTOs & Validation
- Use `class-validator` + `class-transformer` — always.
- `@IsString()`, `@IsEmail()`, `@IsInt()`, `@Min()`, `@Max()`, `@IsOptional()`, etc.
- `PartialType(CreateDto)` for update DTOs — DRY.
- `PickType`, `OmitType`, `IntersectionType` for DTO composition.

```ts
// create-user.dto.ts
import { IsEmail, IsString, MinLength, IsEnum } from "class-validator";

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsEnum(Role)
  role: Role;
}

// update-user.dto.ts
import { PartialType } from "@nestjs/mapped-types";
export class UpdateUserDto extends PartialType(CreateUserDto) {}
```

### Services & Exception Handling
```ts
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
  ) {}

  async findOneOrFail(id: number): Promise<User> {
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }

  async create(dto: CreateUserDto): Promise<User> {
    const existing = await this.usersRepo.findOne({ where: { email: dto.email } });
    if (existing) throw new ConflictException("Email already in use");
    const user = this.usersRepo.create(dto);
    return this.usersRepo.save(user);
  }
}
```

### Guards, Interceptors, Pipes
- **Guards** (`@UseGuards`): auth, roles, rate limiting — return `true`/`false`.
- **Interceptors** (`@UseInterceptors`): transform response, logging, caching.
- **Pipes** (`@UsePipes`): validate and transform input.
- **Filters** (`@UseFilters`): catch exceptions and return structured error responses.
- Register globally in `main.ts` or module-level — prefer global for consistency.

```ts
// roles.guard.ts
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles) return true;
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some(role => user.roles.includes(role));
  }
}
```

### Authentication (JWT + Passport)
- `@nestjs/passport` + `passport-jwt` + `@nestjs/jwt`.
- `JwtStrategy` validates token; `JwtAuthGuard` protects routes.
- Store `userId` and `roles` in JWT payload — minimal, no sensitive data.
- Refresh tokens: store hashed in DB; rotate on use.

```ts
// jwt.strategy.ts
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.getOrThrow<string>("JWT_SECRET"),
    });
  }

  validate(payload: JwtPayload) {
    return { userId: payload.sub, email: payload.email, roles: payload.roles };
  }
}
```

### Database — TypeORM
- Use `@nestjs/typeorm` with `TypeOrmModule.forRootAsync()` + `ConfigService`.
- Entities in `entities/` per module — `@Entity()`, `@Column()`, `@OneToMany()`, etc.
- Migrations always — never `synchronize: true` in production.
- Repository pattern: inject with `@InjectRepository(Entity)`.

```ts
// TypeORM async config
TypeOrmModule.forRootAsync({
  imports: [ConfigModule],
  useFactory: (config: ConfigService) => ({
    type: "postgres",
    host: config.getOrThrow("DB_HOST"),
    port: config.getOrThrow<number>("DB_PORT"),
    database: config.getOrThrow("DB_NAME"),
    username: config.getOrThrow("DB_USER"),
    password: config.getOrThrow("DB_PASSWORD"),
    entities: [__dirname + "/**/*.entity{.ts,.js}"],
    migrations: [__dirname + "/migrations/*{.ts,.js}"],
    synchronize: false,   // NEVER true in production
    logging: config.get("NODE_ENV") === "development",
  }),
  inject: [ConfigService],
}),
```

### Configuration
```ts
// config/database.config.ts
export default registerAs("database", () => ({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT ?? "5432", 10),
}));

// Access anywhere
constructor(
  @Inject(databaseConfig.KEY)
  private dbConfig: ConfigType<typeof databaseConfig>,
) {}
```

### Testing (NestJS)
- Unit tests: `Test.createTestingModule()` with mocked providers.
- E2E tests: `@nestjs/testing` + `supertest` — spin up real app.
- Mock services with `jest.fn()` — never mock the database in unit tests.
- Test file naming: `users.service.spec.ts`, `users.e2e-spec.ts`.

```ts
// Unit test — service
describe("UsersService", () => {
  let service: UsersService;
  let repo: jest.Mocked<Repository<User>>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: { findOne: jest.fn(), save: jest.fn() } },
      ],
    }).compile();
    service = module.get(UsersService);
    repo = module.get(getRepositoryToken(User));
  });

  it("throws NotFoundException when user not found", async () => {
    repo.findOne.mockResolvedValue(null);
    await expect(service.findOneOrFail(99)).rejects.toThrow(NotFoundException);
  });
});
```

### Performance & Best Practices
- Use `@nestjs/throttler` for rate limiting on public endpoints.
- `@nestjs/cache-manager` for response caching (Redis in production).
- Interceptors for response serialization (`ClassSerializerInterceptor`) — hide passwords, internal fields with `@Exclude()`.
- Swagger: `@nestjs/swagger` — `@ApiProperty()` on all DTO fields, auto-generated docs at `/api/docs`.
- Health checks: `@nestjs/terminus` — expose `/health` endpoint.

---

