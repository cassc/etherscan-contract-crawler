//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NFTDasMagazine is ERC1155Burnable, Ownable, DefaultOperatorFilterer {
    string public name = "NFTDasMagazineByMikeHager";
    string public symbol = "NFTDME";

    string public contractUri = "https://nftdasmagazine.mikehager.de/contract";

    uint256 public price;

    bool public isMintEnabled = true;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() ERC1155("https://nftdasmagazine.mikehager.de/{id}") {
        _idTracker.increment();
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setPrice(uint256 _price)
        public
        onlyOwner
    {
        price = _price;
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyOwner {
        require(
            to.length == id.length && to.length == amount.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
    }



    function mint(uint256 amount) public payable {
        require(isMintEnabled, "Mint not enabled");
        require(msg.value >= price * amount, "Not enough eth");

        for(uint256 i = 0; i < amount; i++){
            _mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }
        
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}