// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract lycheeAndFriendsNFT is ERC1155, Ownable {
    uint public MINT_STATUS =  1; //0 disable, 1 public sale
    uint public MINT_FEE = 0.2 ether; //0.2 ether
    uint public MAX_SUPPLY = 20;
    uint[] public MINTED_IDS;
    mapping (uint => address) public nftToOwner;
    string private baseURI = "ipfs://Qmaw6QK34W7MBbKPR7HnitKdR9Q7G4NwgMKJf8MMAYLoAv/{id}.json";
    string public name = "Lychee and Friends Collection"; //set ERC1155 contract name
    //string public symbol = "mysymbol"; //set ERC1155 symbol
    event MintSuccessEvent (uint id);

    constructor() ERC1155(baseURI) {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function seteMintFee(uint _feeInt, uint8 _type) public onlyOwner { //type: 0 = ether or 1 = finney
        if(_type == 1) {
            MINT_FEE = _feeInt * 1e15; //finney
        } else {
            MINT_FEE = _feeInt * (1 ether);
        }
    }

    function mint(uint id)
        public payable {
        require(MINT_STATUS > 0, "Mint not start!");
        require(MINTED_IDS.length + 1 <= MAX_SUPPLY, "All items have been sold.");
        require(id >=1 && id <= MAX_SUPPLY, "Item ID is incorrect.");
        require(nftToOwner[id] == address(0), "The item has been sold.");
        require(msg.value >= (1 * MINT_FEE), "Not enough FEE!");

        _mint(msg.sender, id, 1, ''); //mint 1 for nft only
        MINTED_IDS.push(id);
        nftToOwner[id] = msg.sender;

        emit MintSuccessEvent(id);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        private
        onlyOwner
    {
        //not available
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);

        nftToOwner[id] = to;
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);

        for (uint y = 0; y < ids.length; y++) {
            nftToOwner[ids[y]] = to;
        }
    }

    function totalMinted() public view returns (uint) {
      return MINTED_IDS.length;
    }

    function getMintedIds() public view returns (uint[] memory){
        return MINTED_IDS;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is 0!");
        payable(owner()).transfer(address(this).balance);
    }

    function setMintStatus(uint _status) public onlyOwner {
        MINT_STATUS = _status;
    }
}