// SPDX-License-Identifier: MIT
// Library Burn Lib Contract v1.0.0
// Creator: Nothing Rhymes With Entertainment

pragma solidity >=0.8.9 <0.9.0;

library TokenLib {  

    event Burn(address indexed burnAddress, uint256 tokenId, uint256 totalCurrentlyBurned);
    event Mint(uint256 tokenId, address recipient);

    struct TokenStorage {
        mapping(uint256 => address) burned;
        uint256 burnedTotal;
    }
   
    function burn(TokenStorage storage self, uint256 tokenId) internal{
        self.burnedTotal += 1;
        self.burned[tokenId] = msg.sender;
        emit Burn(msg.sender, tokenId, self.burnedTotal);
    }

    function getAddressByBurnedTokenId(TokenStorage storage self, uint256 tokenId) internal view returns (address){
        return self.burned[tokenId];
    }
    function emitEventForMint(uint256 tokenStart, uint256 numMinted, address recipient) internal{
        for (uint i = 0; i < numMinted; i++) {
            emit Mint(tokenStart, recipient);
        }
    }

}