from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


class Settings(BaseSettings):
    database_url: str
    jwt_secret_key: str

    # When True (the default for this project) a visitor may choose the ADMIN
    # role on the public registration form. Set to False in .env to force every
    # self-registered account to CUSTOMER; admins are then created only via
    # create_admin.py. Admin API authorization is unaffected either way —
    # get_admin_user always re-reads the role from the database.
    allow_public_admin_registration: bool = True

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )


settings = Settings()


class Base(DeclarativeBase):
    pass


engine = create_engine(
    settings.database_url,
    echo=True,
)


SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
)

def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()