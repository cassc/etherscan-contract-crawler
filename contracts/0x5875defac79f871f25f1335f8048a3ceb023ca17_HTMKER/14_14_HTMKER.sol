// SPDX-License-Identifier: LGPL-3.0-or-later 

pragma solidity ^0.8.17;

/**
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*+.    .-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=:   :++-.      -*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=.  .=#@@@@@@@*-.     =%@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@#:   -#@@@@@@@@@@@@@#=.    -%@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@%:   =%@@@@@@@@@@@@@@@@@@#-    :%@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@=   -%@@@@@#*#@@@@@@%::[email protected]@@@%=    [email protected]@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@%.  .#@@@@@@@.  *@@@@@%   @@@@@@%-   :@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@#   [email protected]@@@@@@@@:  [email protected]@@@@@   @@@@@@@@*   .%@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@#   [email protected]@@@@@@@@@=  [email protected]@@@@@-  #@@@@@@@@%:  [email protected]@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@%   [email protected]@@@@@@@@@@*  [email protected]@@@@@#  *@@@@@@@@@@:  :@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@-  [email protected]@@@@@@@@@@@@  [email protected]@@@@@@: [email protected]@@@@@@@@@@.  [email protected]@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@%   #@@@%[email protected]@@@@@+ [email protected]@@@@@@# *@@@@@@-%@@@+  [email protected]@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@=   @@@@+   [email protected]@@@@@*#@@@@@@@@@@@@@@@: #@@@%   %@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@:  [email protected]@@@@=   [email protected]@@@@@@@@@@@@@@@@@@@%: [email protected]@@@%   %@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@.   @@@@@@+    [email protected]@@@@@@@@@@@@@@@@*   #@@@@+  [email protected]@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@:   *@@@@@@%-    =#@@@@@@@@@@@@*:  .#@@@@#   [email protected]@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@=   .%@@@@@@@%=.    -+*#%%#*+-   [email protected]@@@@*   [email protected]@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@.    *@@@@@@@@@#+:.          :=%@@@@@#-   :@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@%.    :*@@@@@@@@@@@@%##***#%@@@@@@@*:    [email protected]@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@+      :+*%@@@@@@@@@@@@@@@@@@#+:     =%@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@+:         .::-=======--:      .=#@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@#+-.                    :-*%@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#**++++++++*##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*HTMKER: SHINxMICHI in collaboration with Purebase Studio https://purebase.co/
*/

import '@ERC721A/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@closedsea/OperatorFilterer.sol';

contract HTMKER is ERC721A, ERC2981, OperatorFilterer, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    error CallerIsContractError();
    error BatchSizeError();
    error ContractPausedError();
    error PlaylistMintClosedError();
    error PlaylistTierClosedError();
    error AllowanceAmountError();
    error ExceedsMaxSupplyError();
    error MintClosedError();
    error IncorrectAmountError();
    error MintAmountError();
    error ExceedsPublicMintAmountError();
    error PrivateSaleAmountError();
    error InvalidSignatureError();
    error BelowCurrentSupplyError();
    error CannotIncreaseSupplyError();

    bool public paused;
    bool public minting;
    bool public whitelistminting;
    bool public operatorFilteringEnabled;
    uint256 public constant maxBatchSize = 10;
    uint256 public maxPublicPerWallet = 2;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public cost = 0.22 ether;
    uint256 public maxSupply = 3000;
    uint256 public currentPlaylistTier = 1;
    address public signer;
    string private _baseTokenURI = 'https://meta.purebase.co/api/demo/htmker?id=';
    string public provenance;

    constructor(address _signer) ERC721A("HTMKER", "HTMKER: SHINxMICHI") {
        paused = true;
        signer = _signer;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContractError();
        _;
    }
    function flipPause() public onlyOwner {
        paused = !paused;
    }
    function flipMint() public onlyOwner {
        minting = !minting;
    }
    function flipPlaylistMint() public onlyOwner {
        whitelistminting = !whitelistminting;
    }
    function setItemPrice(uint256 _price) public onlyOwner {
        cost = _price;
    }
    function setNumPerMint(uint256 _max) public onlyOwner {
        maxMintAmountPerTx = _max;
    }
    function setNumPerWallet(uint256 _max) public onlyOwner {
        maxPublicPerWallet = _max;
    }
    function setPlaylistTier(uint256 _tier) public onlyOwner {
        currentPlaylistTier = _tier;
    }
    function setMaxSupply(uint256 _max) external onlyOwner {
        if (_max > maxSupply) revert CannotIncreaseSupplyError();
        if (_max < totalSupply()) revert BelowCurrentSupplyError();
        maxSupply = _max;
    }

    function mintReserves(uint256 quantity) public onlyOwner {
        if(quantity % maxBatchSize != 0) revert BatchSizeError();
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _mint(msg.sender, maxBatchSize);
        }
    }

    function privateSale(address to, uint256 quantity) external onlyOwner {
        if (quantity > 25) revert PrivateSaleAmountError();
        if (totalSupply() + quantity > maxSupply) revert ExceedsMaxSupplyError();

        _mint(to, quantity);
    }

    function playlistMintOwner(uint256 _mintAmount, uint256 _allowance, uint256 _tier, bytes calldata _sig) public payable callerIsUser onlyOwner {
        uint64 _whitelistClaimed = _getAux(msg.sender);
        if(_tier > currentPlaylistTier) revert PlaylistTierClosedError();
        if(_whitelistClaimed + _mintAmount > _allowance) revert AllowanceAmountError();
        if(totalSupply() + _mintAmount > maxSupply) revert ExceedsMaxSupplyError();
        if(msg.value != cost * _mintAmount) revert IncorrectAmountError();
        address sig_recover = keccak256(abi.encodePacked(msg.sender, _allowance, _tier))
            .toEthSignedMessageHash()
            .recover(_sig);

        if(sig_recover != signer) revert InvalidSignatureError();

        _setAux(msg.sender,uint64(_whitelistClaimed + _mintAmount));
        _mint(msg.sender, _mintAmount);
    }

    function playlistMint(uint256 _mintAmount, uint256 _allowance, uint256 _tier, bytes calldata _sig) public payable callerIsUser {
        uint64 _whitelistClaimed = _getAux(msg.sender);
        if(paused) revert ContractPausedError();
        if(!whitelistminting) revert PlaylistMintClosedError();
        if(_tier > currentPlaylistTier) revert PlaylistTierClosedError();
        if(_whitelistClaimed + _mintAmount > _allowance) revert AllowanceAmountError();
        if(totalSupply() + _mintAmount > maxSupply) revert ExceedsMaxSupplyError();
        if(msg.value != cost * _mintAmount) revert IncorrectAmountError();
        address sig_recover = keccak256(abi.encodePacked(msg.sender, _allowance, _tier))
            .toEthSignedMessageHash()
            .recover(_sig);

        if(sig_recover != signer) revert InvalidSignatureError();

        _setAux(msg.sender,uint64(_whitelistClaimed + _mintAmount));
        _mint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable callerIsUser {
        uint64 _whitelistClaimed = _getAux(msg.sender);
        if(paused) revert ContractPausedError();
        if(!minting) revert MintClosedError();
        if(_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert MintAmountError();
        if(totalSupply() + _mintAmount > maxSupply) revert ExceedsMaxSupplyError();
        if(msg.value != cost * _mintAmount) revert IncorrectAmountError();
        if(numberMinted(msg.sender) + _mintAmount > maxPublicPerWallet + _whitelistClaimed) revert ExceedsPublicMintAmountError();
        
        _mint(msg.sender, _mintAmount);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setProvenance(string memory hash) public onlyOwner {
        provenance = hash;
    }
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function setDefaultRoyalty(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}