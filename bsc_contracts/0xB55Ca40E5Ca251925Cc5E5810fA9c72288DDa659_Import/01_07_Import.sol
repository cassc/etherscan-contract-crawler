// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC721 {
    function totalSupply() external returns(uint256);
    function currentTokenId() external view returns(uint256);
    function mint(address _to, uint256 _tokenId, string memory _hashs) external;
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint _tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokenHash(uint256 tokenId) external view returns (string memory);
}

contract Import is Ownable {
    IERC721 public immutable items721;
    mapping(uint => bool) public importRequestId;
    mapping(uint => string[]) public importInfos; // importRequestId => ipfs

    constructor(IERC721 _items721) {
        items721 = _items721;
    }

    function getImportInfos(uint _importRequestId) external view returns(string[] memory) {
        return importInfos[_importRequestId];
    }
    function importNFT(uint tokenId, uint _importRequestId) internal {
        importInfos[_importRequestId].push(items721.tokenHash(tokenId));
        items721.burn(tokenId);

    }
    function importNFTs(uint[] memory tokenIds, uint _importRequestId) external {
        require(!importRequestId[_importRequestId], "Import::importNFTs:Imported");
        for(uint i = 0; i < tokenIds.length; i++) {
            importNFT(tokenIds[i], _importRequestId + i);
        }
        importRequestId[_importRequestId] = true;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}