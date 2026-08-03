// Testes das Firestore Security Rules (firestore.rules): garantem que um
// usuário autenticado nunca lê nem escreve documentos de outro usuário, e que
// um cliente não autenticado não acessa nada. Exige o Firebase Local
// Emulator Suite (roda via `npm test`, que sobe o emulador do Firestore).
//
// Requer rede liberada para baixar o emulador do Firestore na primeira
// execução (bloqueado pela política de rede deste ambiente de
// desenvolvimento) — rode localmente com `npm install && npm test` dentro de
// firestore-tests/.
import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-rotinagpt',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('firestore.rules — isolamento por uid', () => {
  it('o dono pode ler e escrever seus próprios documentos', async () => {
    const alice = testEnv.authenticatedContext('alice-uid').firestore();
    await assertSucceeds(
      alice.doc('users/alice-uid/foods/f1').set({ name: 'Ovo', proteinG: 13 }),
    );
    await assertSucceeds(alice.doc('users/alice-uid/foods/f1').get());
  });

  it('outro usuário autenticado não pode ler dados alheios', async () => {
    const alice = testEnv.authenticatedContext('alice-uid').firestore();
    await alice.doc('users/alice-uid/foods/f1').set({ name: 'Ovo' });

    const bob = testEnv.authenticatedContext('bob-uid').firestore();
    await assertFails(bob.doc('users/alice-uid/foods/f1').get());
  });

  it('outro usuário autenticado não pode escrever em dados alheios', async () => {
    const bob = testEnv.authenticatedContext('bob-uid').firestore();
    await assertFails(
      bob.doc('users/alice-uid/foods/f2').set({ name: 'Invasão' }),
    );
  });

  it('cliente não autenticado não lê nem escreve nada', async () => {
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(anon.doc('users/alice-uid/foods/f1').get());
    await assertFails(anon.doc('users/alice-uid/foods/f3').set({ name: 'x' }));
  });
});
