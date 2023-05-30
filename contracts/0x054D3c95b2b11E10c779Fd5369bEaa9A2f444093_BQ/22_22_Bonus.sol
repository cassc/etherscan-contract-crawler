// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// ********************#********#***#********#*#****#********************
// *******************#:         *%+          =*    [email protected]#******************
// *******************#.         [email protected]=    ..    -#....:@%******************
// *******************#.   *@=   [email protected]=    %@    -%++++*@#******************
// *******************#.   :=:   [email protected]=    %@    -*    [email protected]%******************
// *******************#.        -#@=    %@    -*    [email protected]%******************
// *******************#.   +#=    *=    %@    -*    [email protected]%******************
// *******************#.   *@+    +=    %@    -*    [email protected]%******************
// *******************#.   .-.    +=          -*    [email protected]%******************
// *******************#.          *+          =*    [email protected]%******************
// ********************#%%%%%%%%%@@%#%%%%%%%%%@%#%%%%@#******************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// **********************************************************************
// ************************************************************@nftchef**

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract BQ is
    ERC721A,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer,
    Pausable,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;

    address public Minter;
    bool public revealed = false;
    string public baseURI;
    address[] internal TEAM;
    address internal _SIGNER;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address royaltyReceiver
    ) ERC721A(_name, _ticker) PaymentSplitter(_payees, _shares) {
        TEAM = _payees;
        baseURI = _uri;
        _setDefaultRoyalty(royaltyReceiver, 500);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function mint(address _to, uint256 _quantity) external {
        require(msg.sender == Minter, "Can only be called by Boi");
        _mint(_to, _quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');
        if (revealed) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function airdrop(address[] calldata _wallets) external onlyOwner {
        uint256 wallets = _wallets.length;

        for (uint256 i = 0; i < wallets; i++) {
            if (_wallets[i] != address(0)) {
                _safeMint(_wallets[i], 1);
            }
        }
    }

    function setMinter(address _minter) external onlyOwner {
        Minter = _minter;
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setBaseURI(string memory _URI, bool _reveal) external onlyOwner {
        baseURI = _URI;
        revealed = _reveal;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < TEAM.length; i++) {
            release(payable(TEAM[i]));
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}