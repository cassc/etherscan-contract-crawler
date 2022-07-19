// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Counters.sol";

contract Frens is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint public constant totalsupply = 230;
    uint public constant mintRate = 0.08 ether;
    bool private minted_Private;
    mapping(address => bool) private allowlist;
    string public constant uri = "https://arweave.net/IHbpRtM3KqtirrZU12UFX96mD8xgS5zmF9bk64TzoSw/gray%27s_metadata.json";
    constructor() ERC721("Cryptofrens", "CP") {
    }

    function addWL(address[] calldata _base) external onlyOwner{
        for (uint256 i = 0; i < _base.length; i++) {
            allowlist[_base[i]] = true;
        }
    }

    function safeMint(address to) private {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
    //mint price is 0.08 eth
    function Public_mint() public payable{
        require(totalsupply >= _tokenIdCounter.current() + 1, "minting is over.");
        require(msg.value >= mintRate, "not enough amount.");
        safeMint(msg.sender);

    }

    function Private_mint() public onlyOwner{
        require(!minted_Private, "minting is over.");
        require(totalsupply >= _tokenIdCounter.current() + 1, "minting is over.");
        uint j=1;
        while (j <= 10) {
            safeMint(msg.sender);
            j++;
        }
        minted_Private = true;

    }

    function WL_mint() public {
        require(totalsupply >= _tokenIdCounter.current() + 1, "minting is over.");
        require(allowlist[msg.sender] == true, "You have already minted or not on whitelist.");
        safeMint(msg.sender);
        allowlist[msg.sender] = false;

    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdraw(address _to) public onlyOwner{
        uint amount = address(this).balance;
        (bool sent,) = payable(_to).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}