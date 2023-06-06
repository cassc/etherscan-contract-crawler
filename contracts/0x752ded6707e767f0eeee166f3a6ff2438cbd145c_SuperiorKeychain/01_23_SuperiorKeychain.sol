// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import '../nft-base/ERC721AExtended.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @dev Superior keychain contract
 */
contract SuperiorKeychain is ERC721AExtended, AccessControl, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    /**
     * @dev Key variables for the keychain
     */
    uint16 public maxSupply = 120;

    // ensures max supply can only reach a limit of 446 even if it's changed. (4460/10 ~ 446)
    modifier maxSupplyLimit() {
        require(maxSupply <= 446, 'KCH1');
        _;
    }

    // ensures that minting doesn't exceed the max supply
    modifier isBelowMaxSupply(uint16 _amount) {
        require(totalSupply() + _amount <= maxSupply, 'KCH2');
        _;
    }

    // checks if the length of the arrays are the same
    modifier recipientLengthValid(address[] calldata _addrs, uint16[] calldata _tokenIds) {
        require(_addrs.length == _tokenIds.length, 'KCH4');
        _;
    }

    constructor() ERC721A('Superior Keychain', 'SKCH') {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // sets default royalty to 5%
        _setDefaultRoyalty(_msgSender(), 500);
    }

    function changeMaxSupply(uint16 _max) external onlyRole(DEFAULT_ADMIN_ROLE) maxSupplyLimit() {
        maxSupply = _max;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // mint a specific `_tokenAmts` amount of token IDs to each recipient of `_to`
    function devMintExt(address[] calldata _to, uint16[] calldata _tokenAmts) external onlyRole(DEFAULT_ADMIN_ROLE) recipientLengthValid(_to, _tokenAmts) isBelowMaxSupply(uint16(_tokenAmts.length)) {
        unchecked {
            for (uint16 i; i < uint16(_to.length);) {
                _safeMint(_to[i], _tokenAmts[i]);
                ++i;
            }
        }
    }

    /// TOKEN URI FUNCTIONS
    string private _contractURI;
    string private _baseURI_;

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURI_ = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata contractURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = contractURI_;
    }

    /// ERC2981 + OPERATOR FILTERER
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setApprovalForAll(address _operator, bool _approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function approve(address _operator, uint256 _tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(_operator) {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /********* WITHDRAWALS*************** */
    /// withdraws balance from this contract to admin.
    /// Note: Please do NOT send unnecessary funds to this contract.
    /// This is used as a mechanism to transfer any balance that this contract has to admin.
    /// we will NOT be responsible for any funds transferred accidentally.
    function withdrawFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /// withdraws tokens from this contract to admin.
    /// Note: Please do NOT send unnecessary tokens to this contract.
    /// This is used as a mechanism to transfer any tokens that this contract has to admin.
    /// we will NOT be responsible for any tokens transferred accidentally.
    function withdrawTokens(address _tokenAddr, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 _token = IERC20(_tokenAddr);
        _token.transfer(_msgSender(), _amount);
    }
    /**************************************** */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, AccessControl, ERC2981) returns (bool) {
        return 
            interfaceId == type(IAccessControl).interfaceId ||
            ERC721A.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}