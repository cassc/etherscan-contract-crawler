// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./AdminAccessControl.sol";
import "./CNCCCal.sol";
import "./CNCCTokenUriSupplier.sol";
import "./interface/ICryptNinjaChildrenCoin.sol";
import "./CNCCEIP2981Royalty.sol";

contract CryptNinjaChildrenCoin is
    ERC1155Supply,
    CNCCCal,
    CNCCEIP2981Royalty,
    CNCCTokenUriSupplier,
    ICryptNinjaChildrenCoin,
    RevokableDefaultOperatorFilterer
{
    string public constant name = 'CryptNinjaChildrenCoin';
    string public constant symbol = 'CNCC';

    address public withdrawAddress = 0x985D66886ea5797D221da4Cc2A5380A5849D08A2;

    constructor() ERC1155('') {
        _grantRole(ADMIN, _msgSender());

        setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7); //Ethereum mainnet proxy
        //setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy
        setCALLevel(1);

        setEnableRestrict(true);

        _setDefaultRoyalty(TokenRoyalty({ recipient: withdrawAddress, bps: 1000 }));

        setBaseURI("https://crypto-ninja-children.s3.ap-northeast-1.amazonaws.com/metadata/");
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, CNCCEIP2981Royalty)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            CNCCEIP2981Royalty.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual override onlyMinter {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external virtual override onlyMinter {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external virtual override onlyBurner {
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external virtual override onlyBurner {
        _burnBatch(account, ids, values);
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyAdmin {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw(address _withdrawAddress) external payable onlyAdmin {
        (bool os, ) = payable(_withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        _setApprovalForAllCheck(operator, approved);

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

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;

        return super.isApprovedForAll(account, operator);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        _beforeTokenTransferCheck(from, to);
    }

    function balanceOf(address account, uint256 id) public view virtual override(ERC1155, ICryptNinjaChildrenCoin) returns (uint256) {
        return ERC1155.balanceOf(account, id);
    }

    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}