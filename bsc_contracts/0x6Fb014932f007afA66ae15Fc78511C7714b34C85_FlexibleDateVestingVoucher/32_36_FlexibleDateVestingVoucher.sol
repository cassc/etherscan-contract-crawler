// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/openzeppelin/utils/ReentrancyGuardUpgradeable.sol";
import "@solv/v2-solidity-utils/contracts/access/AdminControl.sol";
import "@solv/v2-solidity-utils/contracts/misc/Constants.sol";
import "@solv/v2-solidity-utils/contracts/misc/StringConvertor.sol";
import "@solv/v2-solver/contracts/interface/ISolver.sol";
import "@solv/v2-voucher-core/contracts/VoucherCore.sol";
import "./interface/IFlexibleDateVestingVoucher.sol";
import "./interface/IVNFTDescriptor.sol";
import "./FlexibleDateVestingPool.sol";

contract FlexibleDateVestingVoucher is IFlexibleDateVestingVoucher, VoucherCore, ReentrancyGuardUpgradeable {
    using StringConvertor for uint256;

    FlexibleDateVestingPool public flexibleDateVestingPool;

    IVNFTDescriptor public voucherDescriptor;

    ISolver public solver;

    function initialize(
        address flexibleDateVestingPool_,
        address voucherDescriptor_,
        address solver_,
        uint8 unitDecimals_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        VoucherCore._initialize(name_, symbol_, unitDecimals_);
        
        flexibleDateVestingPool = FlexibleDateVestingPool(flexibleDateVestingPool_);
        voucherDescriptor = IVNFTDescriptor(voucherDescriptor_);
        solver = ISolver(solver_);

        ERC165Upgradeable._registerInterface(type(IFlexibleDateVestingVoucher).interfaceId);
    }

    function mint(
        address issuer_,
        uint8 claimType_,
        uint64 latestStartTime_,
        uint64[] calldata terms_,
        uint32[] calldata percentages_,
        uint256 vestingAmount_
    ) 
        external 
        override
        returns (uint256 slot, uint256 tokenId) 
    {
        uint256 err = solver.operationAllowed(
            "mint",
            abi.encode(
                _msgSender(),
                issuer_,
                claimType_,
                latestStartTime_,
                terms_,
                percentages_,
                vestingAmount_
            )
        );
        require(err == 0, "Solver: not allowed");

        require(issuer_ != address(0), "issuer cannot be 0 address");
        require(latestStartTime_ > 0, "latestStartTime cannot be 0");

        slot = getSlot(issuer_, claimType_, latestStartTime_, terms_, percentages_);
        FlexibleDateVestingPool.SlotDetail memory slotDetail = getSlotDetail(slot);
        if (!slotDetail.isValid) {
            flexibleDateVestingPool.createSlot(issuer_, claimType_, latestStartTime_, terms_, percentages_);
        }

        flexibleDateVestingPool.mint(_msgSender(), slot, vestingAmount_);
        tokenId = VoucherCore._mint(_msgSender(), slot, vestingAmount_);

        solver.operationVerify(
            "mint", 
            abi.encode(_msgSender(), issuer_, slot, tokenId, vestingAmount_)
        );
    }

    function claim(uint256 tokenId_, uint256 claimAmount_) external override {
        claimTo(tokenId_, _msgSender(), claimAmount_);
    }

    function claimTo(uint256 tokenId_, address to_, uint256 claimAmount_) public override nonReentrant {
        require(_msgSender() == ownerOf(tokenId_), "only owner");
        require(claimAmount_ <= unitsInToken(tokenId_), "over claim");
        require(isClaimable(voucherSlotMapping[tokenId_]));

        uint256 err = solver.operationAllowed(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimAmount_)
        );
        require(err == 0, "Solver: not allowed");

        flexibleDateVestingPool.claim(voucherSlotMapping[tokenId_], to_, claimAmount_);

        if (claimAmount_ == unitsInToken(tokenId_)) {
            _burnVoucher(tokenId_);
        } else {
            _burnUnits(tokenId_, claimAmount_);
        }

        solver.operationVerify(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimAmount_)
        );

        emit Claim(tokenId_, to_, claimAmount_);
    }

    function setStartTime(uint256 slot_, uint64 startTime_) external override {
        flexibleDateVestingPool.setStartTime(_msgSender(), slot_, startTime_);
    }

    function setVoucherDescriptor(IVNFTDescriptor newDescriptor_) external onlyAdmin {
        emit SetDescriptor(address(voucherDescriptor), address(newDescriptor_));
        voucherDescriptor = newDescriptor_;
    }

    function setSolver(ISolver newSolver_) external onlyAdmin {
        require(newSolver_.isSolver(), "invalid solver");
        emit SetSolver(address(solver), address(newSolver_));
        solver = newSolver_;
    }

    function isClaimable(uint256 slot_) public view override returns (bool) {
        return flexibleDateVestingPool.isClaimable(slot_);
    }

    function getSlot(
        address issuer_, uint8 claimType_, uint64 latestStartTime_,
        uint64[] calldata terms_, uint32[] calldata percentages_
    ) 
        public  
        view 
        returns (uint256) 
    {
        return flexibleDateVestingPool.getSlot(issuer_, claimType_, latestStartTime_, terms_, percentages_);
    }

    function getSlotDetail(uint256 slot_) public view returns (IFlexibleDateVestingPool.SlotDetail memory) {
        return flexibleDateVestingPool.getSlotDetail(slot_);
    }

    function getIssuerSlots(address issuer_) external view returns (uint256[] memory slots) {
        return flexibleDateVestingPool.getIssuerSlots(issuer_);
    }

    function contractURI() external view override returns (string memory) {
        return voucherDescriptor.contractURI();
    }

    function slotURI(uint256 slot_) external view override returns (string memory) {
        return voucherDescriptor.slotURI(slot_);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory) 
    {
        require(_exists(tokenId_), "token not exists");
        return voucherDescriptor.tokenURI(tokenId_);
    }

    function getSnapshot(uint256 tokenId_)
        external
        view
        returns (FlexibleDateVestingVoucherSnapshot memory snapshot)
    {
        snapshot.tokenId = tokenId_;
        snapshot.vestingAmount = unitsInToken(tokenId_);
        snapshot.slotSnapshot = flexibleDateVestingPool.getSlotDetail(voucherSlotMapping[tokenId_]);
        uint64 delayTime = flexibleDateVestingPool.delayTimes(voucherSlotMapping[tokenId_]);
        snapshot.slotSnapshot.latestStartTime += delayTime;
    }

    function underlying() external view override returns (address) {
        return flexibleDateVestingPool.underlyingToken();
    }

    function underlyingVestingVoucher() external view override returns (address) {
        return address(flexibleDateVestingPool.underlyingVestingVoucher());
    }

    function voucherType() external pure override returns (Constants.VoucherType) {
        return Constants.VoucherType.FLEXIBLE_DATE_VESTING;
    }

    function version() external pure returns (string memory) {
        return "2.5";
    }

}