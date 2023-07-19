// SPDX-License-Identifier: MIT

// KATZ Drops by Katz.Community
// author: sadat.eth

pragma solidity ^0.8.19;

/*

                .-=+**######**+=-.                
            :=*####################*=:            
         :=############################+:         
       :*################################*-       
     .*#*########*++==+####*==++*########*#*:     
    =##*==+*##*+======+####*=======*##*+==*##+    
   *###*============+*######*+============*###*   
  *####*==========*############*==========*####*  
 =#####*=========#######**######*=========*#####+ 
.######*========+######====*#####=========*######:
=######*========+######*==================*######+
*######*=========#########**+=============*#######
#######*==========*###########*+==========*#######
*#######============+**#########*=========*#######
+#######=================+*######*========#######+
.#######*=======+******====######*=======*#######:
 +#######*======+######*++*######+======+#######+ 
  *#######*======+##############+======*#######*  
   *########+======*#########*+======+########*.  
    =#########*=======+#####=======*#########+    
     :*##########*++==+####*==++*###########:     
       -*#################################-       
         :+############################+:         
            :=*####################*=:            
                .-=+**#######*+=-:                

*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./closedsea/OperatorFilterer.sol";

contract KatzDrops is ERC1155, ERC2981, Ownable, OperatorFilterer {

    string public name = "Katz Drops";
    string public symbol = "DROP";

    struct Drop {
        uint256 tokenId;
        uint256 price;
        uint256 supply;
        uint256 minted;
        string uri;
    }

    IERC20 public KATZ;
    mapping(uint256 => Drop) public drops;
    bool public operatorFilteringEnabled;

    constructor(address _KATZ) ERC1155("") {
        KATZ = IERC20(_KATZ);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    function createDrop(uint256 tokenId, uint256 price, uint256 supply, string calldata _uri) external onlyOwner {
        require(drops[tokenId].tokenId == 0, "Drop already exists");
        require(supply > 0, "Total supply must be greater than 0");
        drops[tokenId] = Drop(tokenId, price, supply, 0, _uri);
    }

    function updateDrop(uint256 tokenId, uint256 price, uint256 supply, string calldata _uri) external onlyOwner {
        require(drops[tokenId].tokenId != 0, "Drop not exists");
        require(supply >= drops[tokenId].minted, "minted already");
        drops[tokenId] = Drop(tokenId, price, supply, 0, _uri);
    }


    function mintDrop(uint256 tokenId, uint256 amount) external {
        Drop storage drop = drops[tokenId];
        require(drop.tokenId != 0, "Drop does not exist");
        require(drop.minted + amount <= drop.supply, "Drop sold out");
        KATZ.transferFrom(msg.sender, address(this), drop.price * amount);
        _mint(msg.sender, tokenId, amount, "");
        drop.minted += amount;
    }

    function burn(uint256 tokenId, uint256 amount) external {
        require(balanceOf(msg.sender, tokenId) >= amount, "Insufficient tokens");
        _burn(msg.sender, tokenId, amount);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return drops[tokenId].uri;
    }

    function totalSupply(uint256 tokenId) public view virtual returns (uint256) {
        return drops[tokenId].supply;
    }

    function withdraw(uint256 amount) external onlyOwner {
        KATZ.transfer(owner(), amount);
    }

        function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    // Standard functions override for royalties enforcement

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
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC1155: 0xd9b67a26
        // - IERC1155MetadataURI: 0x0e89341c
        // - IERC2981: 0x2a55205a
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}