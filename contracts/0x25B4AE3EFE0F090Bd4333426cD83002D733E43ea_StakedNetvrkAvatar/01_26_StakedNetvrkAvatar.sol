// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../Interfaces/INFTStaking.sol";
import "../Interfaces/INFTRental.sol";

contract StakedNetvrkAvatar is
    Initializable,
    ContextUpgradeable,
    INFTStaking,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721EnumerableUpgradeable
{
    using SafeCastUpgradeable for uint256;

    // NFT base URI
    string internal _baseTokenURI;

    IERC721 private NFT_ERC721;

    INFTRental private NFT_RENTAL;
    mapping(uint256 => StakeInformation) private stakeInformation;

    /**
    ////////////////////////////////////////////////////
    // Admin Functions 
    ///////////////////////////////////////////////////
     */
    function initialize(
        address _nftAddress,
        string memory baseURI
    ) public initializer {
        require(_nftAddress != address(0), "INVALID_NFT_ADDRESS");

        __UUPSUpgradeable_init();
        __ERC721_init("StakedNetvrkAvatars", "SNVKAVT");
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        NFT_ERC721 = IERC721(_nftAddress);
        _baseTokenURI = baseURI;
    }

    function setRentalContract(INFTRental _rentalAddress) external onlyOwner {
        require(
            _rentalAddress.supportsInterface(type(INFTRental).interfaceId),
            "INVALID_RENTAL_ADDRESS"
        );
        NFT_RENTAL = _rentalAddress;
    }

    /**
    ////////////////////////////////////////////////////
    // Public Functions 
    ///////////////////////////////////////////////////
     */

    // Stake the NFT token
    function stake(
        uint256[] calldata _tokenIds,
        address _stakeTo,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRenting
    ) external virtual override nonReentrant {
        require(
            _deposit <= _rentalPerDay * (uint256(_minRentDays) + 1),
            "INVALID_RATE"
        );
        _ensureEOAorERC721Receiver(_stakeTo);
        require(_stakeTo != address(this), "INVALID_STAKE_TO");
        require(
            uint256(_rentableUntil) >=
                block.timestamp + (uint256(_minRentDays) * 1 days),
            "INVALID_RENTABLE_UNTIL"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            require(
                NFT_ERC721.ownerOf(tokenId) == _msgSender(),
                "NFT_NOT_OWNED"
            );
            NFT_ERC721.safeTransferFrom(_msgSender(), address(this), tokenId);
            stakeInformation[tokenId] = StakeInformation(
                _stakeTo,
                _deposit,
                _rentalPerDay,
                _minRentDays,
                _rentableUntil,
                uint32(block.timestamp),
                uint32(block.timestamp + 30 days),
                _enableRenting
            );

            _safeMint(_stakeTo, tokenId);

            emit Staked(tokenId, _stakeTo);
        }
    }

    // Update rental conditions as long as therer's no ongoing rent.
    // setting rentableUntil to 0 makes the world unrentable.
    function updateRent(
        uint256[] calldata _tokenIds,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRenting
    ) external virtual override {
        require(
            _deposit <= _rentalPerDay * (uint256(_minRentDays) + 1),
            "INVALID_RATE"
        );

        require(
            uint256(_rentableUntil) >=
                block.timestamp + (uint256(_minRentDays) * 1 days),
            "INVALID_RENTABLE_UNTIL"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            StakeInformation storage stakeInfo_ = stakeInformation[tokenId];
            require(
                NFT_ERC721.ownerOf(tokenId) == address(this) &&
                    stakeInfo_.owner == _msgSender(),
                "NFT_NOT_OWNED"
            );

            if (address(NFT_RENTAL) != address(0)) {
                require(!NFT_RENTAL.isRentActive(tokenId), "ACTIVE_RENT"); // EB: Ongoing rent
            }

            stakeInfo_.deposit = _deposit;
            stakeInfo_.rentalPerDay = _rentalPerDay;
            stakeInfo_.minRentDays = _minRentDays;
            stakeInfo_.rentableUntil = _rentableUntil;
            stakeInfo_.enableRenting = _enableRenting;
        }
    }

    // Extend rental period of ongoing rent
    function extendRentalPeriod(
        uint256 _tokenId,
        uint32 _rentableUntil
    ) external virtual override {
        StakeInformation storage stakeInfo_ = stakeInformation[_tokenId];
        require(
            NFT_ERC721.ownerOf(_tokenId) == address(this) &&
                stakeInfo_.owner == _msgSender(),
            "NFT_NOT_OWNED"
        ); // E9: Not your world
        require(
            _rentableUntil >=
                block.timestamp + (uint256(stakeInfo_.minRentDays) * 1 days),
            "INVALID_RENTABLE_UNTIL"
        );
        stakeInfo_.rentableUntil = _rentableUntil;
    }

    // Unstake tokens and remove rental
    function unstake(
        uint256[] calldata _tokenIds,
        address _unstakeTo
    ) external virtual override nonReentrant {
        _ensureEOAorERC721Receiver(_unstakeTo);
        require(_unstakeTo != address(this), "INVALID_STAKE_TO");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(
                stakeInformation[tokenId].owner == _msgSender(),
                "NFT_NOT_OWNED"
            );

            require(
                block.timestamp >= stakeInformation[tokenId].lockUntil,
                "STAKE_LOCKED_30_DAYS"
            );

            if (address(NFT_RENTAL) != address(0)) {
                require(!NFT_RENTAL.isRentActive(tokenId), "ACTIVE_RENT"); // EB: Ongoing rent
            }

            NFT_ERC721.safeTransferFrom(address(this), _unstakeTo, tokenId);
            stakeInformation[tokenId] = StakeInformation(
                address(0),
                0,
                0,
                0,
                0,
                0,
                0,
                false
            );

            _burn(tokenId);
            emit Unstaked(tokenId, _msgSender());
        }
    }

    /**
    ////////////////////////////////////////////////////
    // NFT functions
    ///////////////////////////////////////////////////
     */

    // Set base URI
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    // Get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    ////////////////////////////////////////////////////
    // View only functions
    ///////////////////////////////////////////////////
     */

    // Get NFT Address
    function getNFTAddress() external view override returns (address) {
        return address(NFT_ERC721);
    }

    // Get Rental contract address
    function getRentalContractAddress()
        external
        view
        override
        returns (address)
    {
        return address(NFT_RENTAL);
    }

    // Get stake information
    function getStakeInformation(
        uint256 _tokenId
    ) external view override returns (StakeInformation memory) {
        return stakeInformation[_tokenId];
    }

    // Get owner of the staking tokens
    function getOriginalOwner(
        uint256 _tokenId
    ) external view override returns (address) {
        if (NFT_ERC721.ownerOf(_tokenId) == address(this)) {
            return stakeInformation[_tokenId].owner;
        }

        return NFT_ERC721.ownerOf(_tokenId);
    }

    // Get stake duration information
    function getStakingDuration(
        uint256 _tokenId
    ) external view override returns (uint256) {
        if (stakeInformation[_tokenId].stakedFrom == 0) {
            return 0;
        }
        return block.timestamp - stakeInformation[_tokenId].stakedFrom;
    }

    // Get if the stake is active or inactive
    function isStakeActive(
        uint256 _tokenId
    ) public view override returns (bool) {
        return
            stakeInformation[_tokenId].owner != address(0) &&
            ownerOf(_tokenId) != address(0);
    }

    /**
    ////////////////////////////////////////////////////
    // Internal Functions 
    ///////////////////////////////////////////////////
     */

    // UUPS proxy function
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        from;
        tokenId;
        data; // supress solidity warnings
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        } else {
            return 0x00000000;
        }
    }

    function _ensureEOAorERC721Receiver(address to) internal virtual {
        uint32 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    address(this),
                    address(this),
                    0,
                    ""
                )
            returns (bytes4 retval) {
                require(
                    retval == IERC721Receiver.onERC721Received.selector,
                    "INVALID_RECEIVER"
                );
            } catch (bytes memory) {
                revert("INVALID_RECEIVER");
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(from == address(0) || to == address(0), "TRANSFER_LOCKED");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFTStaking).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}