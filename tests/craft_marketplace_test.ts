import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can list a new item",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.uint(1),
                types.ascii("Handmade Scarf"),
                types.utf8("Beautiful winter scarf"),
                types.uint(100000000) // 100 STX
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);
    },
});

Clarinet.test({
    name: "Can purchase a listed item",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        // First list an item
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.uint(1),
                types.ascii("Handmade Scarf"),
                types.utf8("Beautiful winter scarf"),
                types.uint(100000000) // 100 STX
            ], seller.address)
        ]);
        
        // Then purchase it
        let purchaseBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'purchase-item', [
                types.principal(seller.address)
            ], buyer.address)
        ]);
        
        purchaseBlock.receipts[0].result.expectOk();
        
        // Verify seller stats updated
        let statsBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'get-seller-stats', [
                types.principal(seller.address)
            ], seller.address)
        ]);
        
        const stats = statsBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(stats['items-sold'], types.uint(1));
    },
});

Clarinet.test({
    name: "Can update listing price",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const seller = accounts.get('wallet_1')!;
        
        // First list an item
        let block = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'list-item', [
                types.uint(1),
                types.ascii("Handmade Scarf"),
                types.utf8("Beautiful winter scarf"),
                types.uint(100000000) // 100 STX
            ], seller.address)
        ]);
        
        // Update the price
        let updateBlock = chain.mineBlock([
            Tx.contractCall('craft_marketplace', 'update-listing', [
                types.uint(150000000) // 150 STX
            ], seller.address)
        ]);
        
        updateBlock.receipts[0].result.expectOk();
    },
});