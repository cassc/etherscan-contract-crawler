pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "./extension/SignatureMintERC721Upgradeable.sol";

contract SpacebarNFTv1 is SignatureMintERC721Upgradeable, ERC721AUpgradeable, OwnableUpgradeable {
    uint256 public MAX_SUPPLY;
    string public BASE_URI;

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize() initializerERC721A initializer public {
        __ERC721A_init('Spacebar', 'SBAR');
        __SignatureMintERC721_init();
        __Ownable_init();
        MAX_SUPPLY = 333;
        BASE_URI = 'https://nft.statesdao.club/api/collections/spacebar/metadata/';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        BASE_URI = _baseURI;
    }

    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return _signer == owner();
    }

    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
    external
    payable
    returns (address signer) {
        require(_req.quantity > 0, '0 qty!');
        require(_req.to != address(0), 'address(0)');
        require(msg.value >= _req.quantity * _req.pricePerToken, 'Ether too low for minting!');

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        uint256 tokenIdToMint = ERC721AStorage.layout()._currentIndex;
        require(tokenIdToMint + _req.quantity - 1 < MAX_SUPPLY, "Max supply reached");

        (bool sent, bytes memory data) = _req.primarySaleRecipient.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        address receiver = _req.to;
        _safeMint(receiver, _req.quantity);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }
}