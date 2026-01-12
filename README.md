# 💰 GranaZap PRO V2

Sistema completo de gestão financeira desenvolvido com Next.js e Supabase.

## 🚀 Tecnologias

- **Framework**: [Next.js 16](https://nextjs.org) com App Router
- **Linguagem**: TypeScript
- **Estilização**: Tailwind CSS v4
- **Backend**: [Supabase](https://supabase.com) (PostgreSQL + Auth)
- **Gerenciamento de Estado**: Zustand
- **Consultas de Dados**: TanStack Query (React Query)
- **Formulários**: React Hook Form + Zod
- **Gráficos**: Recharts
- **Animações**: Framer Motion
- **UI Components**: Radix UI
- **Internacionalização**: next-intl

## 📋 Funcionalidades

- ✅ Autenticação de usuários
- ✅ Gestão de receitas e despesas
- ✅ Dashboard com gráficos e estatísticas
- ✅ Relatórios em PDF
- ✅ Sistema de categorias
- ✅ Interface responsiva e moderna
- ✅ Modo escuro/claro
- ✅ Internacionalização (i18n)

## 🛠️ Instalação

1. Clone o repositório:
```bash
git clone https://github.com/war721/GranaZap_PRO_V2.git
cd GranaZap_PRO_V2
```

2. Instale as dependências:
```bash
npm install
```

3. Configure as variáveis de ambiente:
Crie um arquivo `.env.local` baseado no `.env.example` com suas credenciais do Supabase:
```env
NEXT_PUBLIC_SUPABASE_URL=sua_url_do_supabase
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua_chave_anonima
```

4. Execute o servidor de desenvolvimento:
```bash
npm run dev
```

5. Abra [http://localhost:3000](http://localhost:3000) no navegador.

## 📁 Estrutura do Projeto

```
granazap/
├── src/
│   ├── app/              # App Router (páginas e rotas)
│   ├── components/       # Componentes React reutilizáveis
│   ├── lib/             # Bibliotecas e utilitários
│   ├── hooks/           # Custom React Hooks
│   └── types/           # Definições TypeScript
├── public/              # Arquivos estáticos
├── supabase/            # Configurações do Supabase
└── package.json
```

## 🔧 Scripts Disponíveis

- `npm run dev` - Inicia o servidor de desenvolvimento
- `npm run build` - Cria a build de produção
- `npm start` - Inicia o servidor de produção
- `npm run lint` - Executa o linter

## 🗄️ Banco de Dados

O projeto utiliza Supabase (PostgreSQL) para armazenamento de dados. As migrações e esquemas estão na pasta `supabase/`.

## 📝 Licença

Este projeto é privado e de uso exclusivo.

## 👨‍💻 Desenvolvedor

Desenvolvido por [war721](https://github.com/war721)

---

**Versão**: 2.0.0  
**Última atualização**: Janeiro 2026
