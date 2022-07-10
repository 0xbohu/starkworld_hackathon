import Head from 'next/head'
import styles from '../styles/Home.module.css'
import { StarknetProvider } from '/src/@core/context/starknetContext'
import App from './App';


export default function Home() {


  return (
    <StarknetProvider>
    <div className={styles.container}>
      <Head>
        <title>StarkWorld</title>
        <meta name="description" content="StarkWorld Metaverse" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className={styles.main}>
      <App />
      </main>
    </div>
    </StarknetProvider>
  )
}
