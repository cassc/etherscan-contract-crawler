// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/[email protected]/token/ERC1155/ERC1155.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";
import "@openzeppelin/[email protected]/interfaces/IERC2981.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155Supply.sol";
import "operator-filter/DefaultOperatorFilterer.sol";



interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external returns(uint256);
}


/// @custom:security-contact [email protected]
contract TrumpsterFire is ERC1155, IERC2981, DefaultOperatorFilterer, AccessControl, ERC1155Supply {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    uint16 public constant MAX_SUPPLY = 45001;
    uint256 public constant MINT_PRICE = 0.05 ether;
    uint16 private constant NUM_TRUMPSTERS = 100;
    uint16 private issued;
    address private _recipient;

    constructor() ERC1155("ipfs://QmRfTRSpTexGn5bJZmGT7jrGwvmiBU4CVGNyHfV7mw8Aw4/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
        issued = 0;
        _recipient = msg.sender;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }
    
    function mint(uint16 qty)
        public payable
    {
        require(qty > 0, "You have to mint at least one");
        require(issued + qty <= MAX_SUPPLY, "Exceeds token supply");
        require(msg.value >= MINT_PRICE * qty, "Not enough ETH sent: check price.");
        for(uint16 i = 0; i<qty; i++) {
            _mint(msg.sender, random() % NUM_TRUMPSTERS, 1, "");
            issued = issued + 1;
        }
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, issued)));       
    }

    function withdraw() public onlyRole(WITHDRAWER_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(address _tokenContract) public onlyRole(WITHDRAWER_ROLE) {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155, AccessControl)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyRole(WITHDRAWER_ROLE) {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 500) / 10000);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
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