// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./src/ERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error GameNotStartedYet();
error RestrictedMint();
error TooManyAdams();
error ExceedsMaxPerWallet();
error WithdrawFailed();
error TokenNotFound();
error InsufficientFunds();

contract houseofadam is ERC721A, Ownable, DefaultOperatorFilterer {
    uint256 public constant maxAdam = 5000;
    uint256 public constant walletLimit = 3;
    uint256 public price = 0.0025 ether;
    bool public gameStart = false;
    string public baseURI = "";
    uint256 counter = 0;

    constructor() ERC721A("House Of Adam", "HOA") 
    {
        _mint(msg.sender, 1);
    }

    /// @notice First 500 are free, the rest depends on your luck..
    function play(uint256 _qty) external payable 
    {
        uint256 tempAdam = _totalMinted() + _qty;
        if(!gameStart) revert GameNotStartedYet();
        if(tempAdam > maxAdam) revert TooManyAdams();
        if(tx.origin != msg.sender) revert RestrictedMint();
        if(_numberMinted(msg.sender) + _qty > walletLimit) revert ExceedsMaxPerWallet();

        if(tempAdam > 500)
        {
            counter++;
            uint256 rand = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,counter))) % 2;
            if(rand == 0){
                //lucky! free mint & refund
                payable(msg.sender).transfer(msg.value);
            }else{
                //unlucky, pay to mint
                if(msg.value < _qty * price) revert InsufficientFunds();
            }
        }

        _mint(msg.sender, _qty);
    }

    function setBaseURI(string calldata newURI) public onlyOwner 
    {
        baseURI = newURI;
    }

    function withdraw() external onlyOwner 
    {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert WithdrawFailed();
    }

    function setPrice(uint256 _price) public onlyOwner 
    {
        price = _price;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) 
    {
        if(!_exists(tokenId)) revert TokenNotFound();
        return string(abi.encodePacked(baseURI,_toString(tokenId), ".json"));
    }

    function game(bool _state) external onlyOwner 
    {
        gameStart = _state;
    }

    function _startTokenId() internal view virtual override returns (uint256) 
    {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) 
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public
        payable
        override 
        onlyAllowedOperatorApproval(operator) 
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}