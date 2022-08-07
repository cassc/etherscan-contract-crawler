//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract Genesis is ERC721AUpgradeable, OwnableUpgradeable {

    uint public price;
    bool public mintingPaused;
    address private _withdrawalAddress;
    string private _currentBaseUri;

    uint public constant MINTING_LIMIT = 800;

    function initialize(address withdrawalAddress_) initializerERC721A initializer public {
        __ERC721A_init("Genesis", "GEN");
        __Ownable_init();

        price = 0.125 ether;
        mintingPaused = false;
        _currentBaseUri = "https://nft.genesismint.io/";
        _withdrawalAddress = withdrawalAddress_;
    }

    function mint(uint256 quantity) external payable {
        require(!mintingPaused, "MintingIsPaused");
        uint256 currentId = _nextTokenId() - 1;
        uint256 nextId = currentId + quantity;
        require(nextId <= MINTING_LIMIT && !(currentId < 50 && nextId > 50) && !(currentId < 750 && nextId > 750), "MintLimitReached");
        require(msg.value >= price * quantity, "NotEnoughEther");
        require(nextId <= 750 || msg.sender == _withdrawalAddress, "OnlyOwnerCanMintNow");
        require((currentId == 0 && quantity <= 50) || quantity <= 10, "BatchMintSizeRestricted");

        _mint(msg.sender, quantity);

        if (nextId == 50 || nextId == 750) {
            mintingPaused = true;
        }
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_currentBaseUri, "contract-metadata.json"));
    }

    function setPrice(uint newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMintingPaused(bool newMintingPaused) public onlyOwner {
        mintingPaused = newMintingPaused;
    }

    function setBaseUri(string calldata newBaseUri) public onlyOwner {
        _currentBaseUri = newBaseUri;
    }

    function triggerWithdrawal() public onlyOwner {
        (bool sent, bytes memory data) = payable(_withdrawalAddress).call{value: address(this).balance}("");
        require(sent, "WithdrawalFailed");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}