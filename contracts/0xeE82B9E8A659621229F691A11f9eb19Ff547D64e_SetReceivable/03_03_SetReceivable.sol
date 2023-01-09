// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
struct ReceivableData { 
    mapping(address => mapping(address => uint256[])) receivedTokens;

    mapping(address => address[]) stakedContracts;

    mapping(address => mapping(address => uint256)) stakedContractIndex;

    mapping(address => mapping(uint256 => uint256)) receivedTokensIndex;    
    
    mapping(address => mapping(address => uint256)) walletBalances;
} 

interface Holdable {
    function balanceOf(address owner) external returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
}
error MintNotLive();

error ReceivedTokenNonExistent(uint256 tokenId);

error ReceivedTokenNonOwner(address requester, uint256 tokenId);  

library SetReceivable {    
 
    function balanceOfWallet(ReceivableData storage self, address wallet, address contracted) public view returns (uint256) {        
        return self.walletBalances[wallet][contracted];
    }

    function receivedFromWallet(ReceivableData storage self, address wallet, address contracted) public view returns (uint256[] memory) {        
        return self.receivedTokens[wallet][contracted];
    }    

    function _addTokenToReceivedEnumeration(ReceivableData storage self, address from, address contracted, uint256 tokenId) public {
        uint256 length = balanceOfWallet(self,from,contracted);
        
        if (length >= self.receivedTokens[from][contracted].length) {
            length = self.receivedTokens[from][contracted].length;
            self.receivedTokens[from][contracted].push(tokenId);
            // revert ReceivedTokenNonExistent(self.receivedTokens[from][contracted][0]);
        } else {
            self.receivedTokens[from][contracted][length] = tokenId;    
            
        }
        self.receivedTokensIndex[contracted][tokenId] = length;
        self.walletBalances[from][contracted]++;
        if (self.receivedTokens[from][contracted].length < 1) {
            revert ReceivedTokenNonExistent(tokenId);
        }     

        if (length < 1) {
            self.stakedContracts[from].push(contracted);
            self.stakedContractIndex[from][contracted] = self.stakedContracts[from].length;
        }    
    }    

    function _removeTokenFromReceivedEnumeration(ReceivableData storage self, address from, address contracted, uint256 tokenId) public {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).  

        // if (self.receivedTokens[from][contracted].length < 1) {
        //     revert ReceivedTokenNonExistent(tokenId);
        // }      

        // When the token to delete is the last token, the swap operation is unnecessary
        if (self.receivedTokens[from][contracted].length > self.receivedTokensIndex[contracted][tokenId]) {
            if (self.receivedTokensIndex[contracted][tokenId] != self.receivedTokens[from][contracted].length - 1) {
                uint256 lastTokenId = self.receivedTokens[from][contracted][balanceOfWallet(self,from,contracted) - 1];
                
                self.receivedTokens[from][contracted][self.receivedTokensIndex[contracted][tokenId]] = lastTokenId; // Move the last token to the slot of the to-delete token
                self.receivedTokensIndex[contracted][lastTokenId] = self.receivedTokensIndex[contracted][tokenId]; // Update the moved token's index
            }
        } 
        

        // This also deletes the contents at the last position of the array
        delete self.receivedTokensIndex[contracted][tokenId];
        self.receivedTokens[from][contracted].pop();
        self.walletBalances[from][contracted]--;

        uint256 left = balanceOfWallet(self,from,contracted);

        if (left < 1) {
            if (self.stakedContracts[from].length > self.stakedContractIndex[from][contracted]) {
                if (self.stakedContractIndex[from][contracted] != self.stakedContracts[from].length - 1) {
                
                    address lastContract = self.stakedContracts[from][self.stakedContracts[from].length - 1];

                    self.stakedContracts[from][self.stakedContracts[from].length - 1] = contracted;
                    self.stakedContracts[from][self.stakedContractIndex[from][contracted]] = lastContract;                
                }
            }
            self.stakedContracts[from].pop();
            delete self.stakedContractIndex[from][contracted];
        } 
    }    

    function tokenReceivedByIndex(ReceivableData storage self, address wallet, address contracted, uint256 index) public view returns (uint256) {
        return self.receivedTokens[wallet][contracted][index];
    }    

    function swapOwner(ReceivableData storage self, address from, address to) public {
        for (uint256 contractIndex = 0; contractIndex < self.stakedContracts[from].length; contractIndex++) {
            address contractToSwap = self.stakedContracts[from][contractIndex];
            
            uint256 tokenId = self.receivedTokens[from][contractToSwap][0];
            while (self.receivedTokens[from][contractToSwap].length > 0) {
                _removeTokenFromReceivedEnumeration(self,from,contractToSwap,tokenId);
                _addTokenToReceivedEnumeration(self,to,contractToSwap,tokenId);
                if ((self.receivedTokens[from][contractToSwap].length > 0)) {
                    tokenId = self.receivedTokens[from][contractToSwap][0];
                }
            }
        }
    }

    function withdraw(ReceivableData storage self, address contracted, uint256[] calldata tokenIds) public {        
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Holdable held = Holdable(contracted);
            if (held.ownerOf(tokenId) != address(this)) {
                revert ReceivedTokenNonOwner(address(this),tokenId);
            }
         
            _removeTokenFromReceivedEnumeration(self,msg.sender,contracted,tokenId);
            IERC721(contracted).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
    }
}