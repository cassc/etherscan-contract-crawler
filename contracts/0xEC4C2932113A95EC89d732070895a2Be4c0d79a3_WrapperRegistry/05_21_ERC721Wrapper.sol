// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IERC721Wrapper} from "./interfaces/IERC721Wrapper.sol";
import {IWrapperValidator} from "./interfaces/IWrapperValidator.sol";
import {IFlashLoanReceiver} from "./interfaces/IFlashLoanReceiver.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract ERC721Wrapper is
    IERC721Wrapper,
    IERC721ReceiverUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC721Upgradeable
{
    IERC721MetadataUpgradeable public override underlyingToken;
    IWrapperValidator public override validator;
    bool public override isFlashLoanEnabled;
    bool public override isMintEnabled;

    modifier whenFlashLoanEnabled() {
        require(isFlashLoanEnabled, "ERC721Wrapper: flash loan disabled");
        _;
    }

    modifier whenMintEnabled() {
        require(isMintEnabled, "ERC721Wrapper: mint disabled");
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;

    function __ERC721Wrapper_init(
        IERC721MetadataUpgradeable underlyingToken_,
        IWrapperValidator validator_,
        string memory name,
        string memory symbol
    ) internal onlyInitializing {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __ERC721_init(name, symbol);

        require(validator_.underlyingToken() == address(underlyingToken_), "ERC721Wrapper: underlying token mismatch");
        underlyingToken = underlyingToken_;
        validator = validator_;

        isMintEnabled = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721Wrapper).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(_msgSender() == address(underlyingToken), "ERC721Wrapper: not acceptable erc721");
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function updateValidator(address validator_) external override onlyOwner {
        require(
            IWrapperValidator(validator_).underlyingToken() == address(underlyingToken),
            "Validator: underlying token mismatch"
        );
        address preValidator = address(validator);
        validator = IWrapperValidator(validator_);
        emit ValidatorUpdated(preValidator, address(validator));
    }

    function mint(uint256 tokenId) external override nonReentrant whenNotPaused whenMintEnabled {
        address owner = underlyingToken.ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721Wrapper: only owner can mint");
        require(validator.isValid(address(underlyingToken), tokenId), "ERC721Wrapper: token id not valid");

        underlyingToken.safeTransferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);
    }

    function burn(uint256 tokenId) external override nonReentrant whenNotPaused {
        require(_msgSender() == ownerOf(tokenId), "ERC721Wrapper: only owner can burn");
        address owner = underlyingToken.ownerOf(tokenId);
        require(address(this) == owner, "ERC721Wrapper: invalid tokenId");

        underlyingToken.safeTransferFrom(address(this), _msgSender(), tokenId);
        _burn(tokenId);
    }

    function setFlashLoanEnabled(bool value) public onlyOwner {
        isFlashLoanEnabled = value;

        emit FlashLoanEnabled(value);
    }

    function setMintEnabled(bool value) public onlyOwner {
        isMintEnabled = value;

        emit MintEnabled(value);
    }

    function flashLoan(
        address receiverAddress,
        uint256[] calldata tokenIds,
        bytes calldata params
    ) external override nonReentrant whenNotPaused whenFlashLoanEnabled {
        uint256 i;
        IFlashLoanReceiver receiver = IFlashLoanReceiver(receiverAddress);

        // !!!CAUTION: receiver contract may reentry mint, burn, flashloan again

        require(receiverAddress != address(0), "ERC721Wrapper: can't be zero address");
        require(tokenIds.length > 0, "ERC721Wrapper: empty tokenIds");

        // only token owner can do flashloan
        for (i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == _msgSender(), "ERC721Wrapper: caller is not owner");
        }

        // step 1: moving underlying asset forward to receiver contract
        for (i = 0; i < tokenIds.length; i++) {
            underlyingToken.safeTransferFrom(address(this), receiverAddress, tokenIds[i]);
        }

        // setup 2: execute receiver contract, doing something like aidrop
        require(
            receiver.executeOperation(address(underlyingToken), tokenIds, _msgSender(), address(this), params),
            "ERC721Wrapper: flashloan failed"
        );

        // setup 3: moving underlying asset backword from receiver contract
        for (i = 0; i < tokenIds.length; i++) {
            underlyingToken.safeTransferFrom(receiverAddress, address(this), tokenIds[i]);

            emit FlashLoan(receiverAddress, _msgSender(), address(underlyingToken), tokenIds[i]);
        }
    }

    function setPause(bool flag) public onlyOwner {
        if (flag) {
            _pause();
        } else {
            _unpause();
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721MetadataUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return underlyingToken.tokenURI(tokenId);
    }
}