// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./modules/Ownable/Ownable.sol";
import "./modules/Upgradeable/Upgradeable.sol";
import "./TransferHelper.sol";
import "./IWorldsEscrow.sol";
import "./IWorldsRental.sol";
import "./IWorlds_ERC721.sol";
import "./WorldsRentalStorage.sol";

contract WorldsRental is Context, ERC165, IWorldsRental, Ownable, ReentrancyGuard, Upgradeable {
    using SafeCast for uint;

    // ======== Admin functions ========
    constructor(address _paymentTokenAddress, IWorldsEscrow _escrow) {
        require(_paymentTokenAddress != address(0), "E0"); // E0: addr err
        require(_escrow.supportsInterface(type(IWorldsEscrow).interfaceId),"E0");
        WorldsRentalStorage.layout().paymentTokenAddress = _paymentTokenAddress;
        WorldsRentalStorage.layout().WorldsEscrow = _escrow;
    }

    function setPaymentTokenAddress(address _paymentTokenAddress) external onlyOwner checkForUpgrade {
        WorldsRentalStorage.layout().paymentTokenAddress = _paymentTokenAddress;
    }

    function setWorldsEscrow(IWorldsEscrow _escrow) external onlyOwner checkForUpgrade {
        WorldsRentalStorage.layout().WorldsEscrow = _escrow;
    }

    // ======== Public functions ========

    // Can be used by tenant to initiate rent
    // Can be used on a world where rental payment has expired
    // paymentAlert is the number of seconds before an alert can be rentalPerDay
    // payment unit in ether
    function rentWorld(uint _tokenId, uint32 _paymentAlert, uint32 _initialPayment) external nonReentrant checkForUpgrade {
        IWorldsEscrow.WorldInfo memory worldInfo_ = WorldsRentalStorage.layout().WorldsEscrow.getWorldInfo(_tokenId);
        WorldRentInfo memory worldRentInfo_ = WorldsRentalStorage.layout().worldRentInfo[_tokenId];
        require(worldInfo_.owner != address(0), "EN"); // EN: Not staked
        require(uint(worldInfo_.rentableUntil) >= block.timestamp + worldInfo_.minRentDays * 86400, "EC"); // EC: Not available
        if (worldRentInfo_.tenant != address(0)) { // if previously rented
            uint paidUntil = rentalPaidUntil(_tokenId);
            require(paidUntil < block.timestamp, "EB"); // EB: Ongoing rent
            worldRentInfo_.rentalPaid = 0; // reset payment amount
        }
        // should pay at least deposit + 1 day of rent
        require(uint(_initialPayment) >= uint(worldInfo_.deposit + worldInfo_.rentalPerDay), "ED"); // ED: Payment insufficient
        // prevent the user from paying too much
        // block.timestamp casts it into uint256 which is desired
        // if the rentable time left is less than minRentDays then the tenant just has to pay up until the time limit
        uint paymentAmount = Math.min((worldInfo_.rentableUntil - block.timestamp) * worldInfo_.rentalPerDay / 86400,
                                    uint(_initialPayment));
        worldRentInfo_.tenant = _msgSender();
        worldRentInfo_.rentStartTime = block.timestamp.toUint32();
        worldRentInfo_.rentalPaid += paymentAmount.toUint32();
        worldRentInfo_.paymentAlert = _paymentAlert;
        TransferHelper.safeTransferFrom(WorldsRentalStorage.layout().paymentTokenAddress, _msgSender(), worldInfo_.owner, paymentAmount * 1e18);
        WorldsRentalStorage.layout().worldRentInfo[_tokenId] = worldRentInfo_;
        uint count = WorldsRentalStorage.layout().rentCount[_msgSender()];
        WorldsRentalStorage.layout().rentedWorlds[_msgSender()][count] = _tokenId;
        WorldsRentalStorage.layout().rentedWorldsIndex[_tokenId] = count;
        WorldsRentalStorage.layout().rentCount[_msgSender()] ++;
        emit WorldRented(_tokenId, _msgSender(), paymentAmount * 1e18);
    }

    // Used by tenant to pay rent in advance. As soon as the tenant defaults the renter can vacate the tenant
    // The rental period can be extended as long as rent is prepaid, up to rentableUntil timestamp.
    // payment unit in ether
    function payRent(uint _tokenId, uint32 _payment) external nonReentrant checkForUpgrade {
        IWorldsEscrow.WorldInfo memory worldInfo_ = WorldsRentalStorage.layout().WorldsEscrow.getWorldInfo(_tokenId);
        WorldRentInfo memory worldRentInfo_ = WorldsRentalStorage.layout().worldRentInfo[_tokenId];
        require(worldRentInfo_.tenant == _msgSender(), "EE"); // EE: Not rented
        // prevent the user from paying too much
        uint paymentAmount = Math.min(uint(worldInfo_.rentableUntil - worldRentInfo_.rentStartTime) * worldInfo_.rentalPerDay / 86400
                                                - worldRentInfo_.rentalPaid,
                                    uint(_payment));
        worldRentInfo_.rentalPaid += paymentAmount.toUint32();
        TransferHelper.safeTransferFrom(WorldsRentalStorage.layout().paymentTokenAddress, _msgSender(), worldInfo_.owner, paymentAmount * 1e18);
        WorldsRentalStorage.layout().worldRentInfo[_tokenId] = worldRentInfo_;
        emit RentalPaid(_tokenId, _msgSender(), paymentAmount * 1e18);
    }

    // Used by renter to vacate tenant in case of default, or when rental period expires.
    // If payment + deposit covers minRentDays then deposit can be used as rent. Otherwise rent has to be provided in addition to the deposit.
    // If rental period is shorter than minRentDays then deposit will be forfeited.
    function terminateRental(uint _tokenId) external checkForUpgrade {
        require(WorldsRentalStorage.layout().WorldsEscrow.getWorldInfo(_tokenId).owner == _msgSender(), "E9"); // E9: Not your world
        uint paidUntil = rentalPaidUntil(_tokenId);
        require(paidUntil < block.timestamp, "EB"); // EB: Ongoing rent
        address tenant = WorldsRentalStorage.layout().worldRentInfo[_tokenId].tenant;
        emit RentalTerminated(_tokenId, tenant);
        WorldsRentalStorage.layout().rentCount[tenant]--;
        uint lastIndex = WorldsRentalStorage.layout().rentCount[tenant];
        uint tokenIndex = WorldsRentalStorage.layout().rentedWorldsIndex[_tokenId];
        // swap and purge if not the last one
        if (tokenIndex != lastIndex) {
            uint lastTokenId = WorldsRentalStorage.layout().rentedWorlds[tenant][lastIndex];

            WorldsRentalStorage.layout().rentedWorlds[tenant][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            WorldsRentalStorage.layout().rentedWorldsIndex[lastTokenId] = tokenIndex;
        }
        delete WorldsRentalStorage.layout().rentedWorldsIndex[_tokenId];
        delete WorldsRentalStorage.layout().rentedWorlds[tenant][tokenIndex];

        WorldsRentalStorage.layout().worldRentInfo[_tokenId] = WorldRentInfo(address(0),0,0,0);
    }


    // ======== View only functions ========
    function isRentActive(uint _tokenId) public view override returns(bool) {
        return WorldsRentalStorage.layout().worldRentInfo[_tokenId].tenant != address(0);
    }

    function getTenant(uint _tokenId) public view override returns(address) {
        return WorldsRentalStorage.layout().worldRentInfo[_tokenId].tenant;
    }

    function rentedByIndex(address _tenant, uint _index) public view returns(uint) {
        require(_index < WorldsRentalStorage.layout().rentCount[_tenant], "EI"); // EI: index out of bounds
        return WorldsRentalStorage.layout().rentedWorlds[_tenant][_index];
    }

    function isRentable(uint _tokenId) external view returns(bool state) {
        IWorldsEscrow.WorldInfo memory worldInfo_ = WorldsRentalStorage.layout().WorldsEscrow.getWorldInfo(_tokenId);
        WorldRentInfo memory worldRentInfo_ = WorldsRentalStorage.layout().worldRentInfo[_tokenId];
        state = (worldInfo_.owner != address(0)) &&
            (uint(worldInfo_.rentableUntil) >= block.timestamp + worldInfo_.minRentDays * 86400);
        if (worldRentInfo_.tenant != address(0)) { // if previously rented
            uint paidUntil = rentalPaidUntil(_tokenId);
            state = state && (paidUntil < block.timestamp);
        }
    }

    function rentalPaidUntil(uint _tokenId) public view returns(uint paidUntil) {
        IWorldsEscrow.WorldInfo memory worldInfo_ = WorldsRentalStorage.layout().WorldsEscrow.getWorldInfo(_tokenId);
        WorldRentInfo memory worldRentInfo_ = WorldsRentalStorage.layout().worldRentInfo[_tokenId];
        if (worldInfo_.rentalPerDay == 0) {
            paidUntil = worldInfo_.rentableUntil;
        }
        else {
            uint rentalPaidSeconds = uint(worldRentInfo_.rentalPaid) * 86400 / worldInfo_.rentalPerDay;
            bool fundExceedsMin = rentalPaidSeconds >= Math.max(worldInfo_.minRentDays * 86400, block.timestamp - worldRentInfo_.rentStartTime);
            paidUntil = uint(worldRentInfo_.rentStartTime) + rentalPaidSeconds
                        - (fundExceedsMin ? 0 : uint(worldInfo_.deposit) * 86400 / worldInfo_.rentalPerDay);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IWorldsRental).interfaceId || super.supportsInterface(interfaceId);
    }

}