// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/openzeppelin/utils/ReentrancyGuardUpgradeable.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/token/ERC20/IERC20.sol";
import "@solv/v2-solidity-utils/contracts/helpers/ERC20TransferHelper.sol";
import "@solv/v2-solidity-utils/contracts/helpers/VNFTTransferHelper.sol";
import "@solv/v2-voucher-core/contracts/VoucherCore.sol";
import "@solv/v2-solver/contracts/interface/ISolver.sol";
import "./BondPool.sol";
import "./interface/IVNFTDescriptor.sol";
import "./interface/IBondVoucher.sol";
import "./interface/external/IICToken.sol";

contract BondVoucher is IBondVoucher, VoucherCore, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    BondPool public bondPool;

    IVNFTDescriptor public voucherDescriptor;

    ISolver public solver;

    function initialize(
        address bondPool_,
        address voucherDescriptor_,
        address solver_,
        uint8 unitDecimals_,
        string calldata name_,
        string calldata symbol_
    )
        external
        initializer
    {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        VoucherCore._initialize(name_, symbol_, unitDecimals_);

        bondPool = BondPool(bondPool_);
        voucherDescriptor = IVNFTDescriptor(voucherDescriptor_);
        solver = ISolver(solver_);

        ERC165Upgradeable._registerInterface(type(IBondVoucher).interfaceId);
    }

    function mint(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint256 tokenInAmount_ // 最大偿付token数量 (at lowestPrice)
    ) 
        external 
        override
        nonReentrant
        returns (uint256 slot, uint256 tokenId) 
    {
        uint256 err = solver.operationAllowed(
            "mint", 
            abi.encode(
                _msgSender(),
                issuer_,
                fundCurrency_,
                lowestPrice_,
                highestPrice_,
                effectiveTime_, 
                maturity_,
                tokenInAmount_
            )
        );
        require(err == 0, "Solver: not allowed");

        slot = getSlot(
            issuer_, fundCurrency_, lowestPrice_, highestPrice_, 
            effectiveTime_, maturity_
        );
        if (!getSlotDetail(slot).isValid) {
            bondPool.createSlot(
                issuer_, fundCurrency_, lowestPrice_, highestPrice_, 
                effectiveTime_, maturity_
            );
        }

        uint256 units = bondPool.mintWithUnderlyingToken(_msgSender(), slot, tokenInAmount_);
        tokenId = VoucherCore._mint(_msgSender(), slot, units);

        solver.operationVerify(
            "mint", 
            abi.encode(_msgSender(), issuer_, slot, tokenId, units)
        );
    }

    function claimAll(uint256 tokenId_) external override {
        claim(tokenId_, unitsInToken(tokenId_));
    }
    
    function claim(uint256 tokenId_, uint256 claimUnits_) public override {
        claimTo(tokenId_, _msgSender(), claimUnits_);
    }

    function claimTo(uint256 tokenId_, address to_, uint256 claimUnits_) public override nonReentrant {
        require(_msgSender() == ownerOf(tokenId_), "only owner");
        require(claimUnits_ <= unitsInToken(tokenId_), "over claim");

        uint256 err = solver.operationAllowed(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimUnits_)
        );
        require(err == 0, "Solver: not allowed");

        (uint256 claimCurrencyAmount, uint256 claimTokenAmount) 
            = bondPool.claim(voucherSlotMapping[tokenId_], to_, claimUnits_);

        if (claimUnits_ == unitsInToken(tokenId_)) {
            _burnVoucher(tokenId_);
        } else {
            _burnUnits(tokenId_, claimUnits_);
        }

        solver.operationVerify(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimUnits_)
        );

        emit Claim(tokenId_, to_, claimUnits_, claimCurrencyAmount, claimTokenAmount);
    }

    function getSlot(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) 
        public  
        view 
        override 
        returns (uint256) 
    {
        return bondPool.getSlot(
            issuer_, fundCurrency_, lowestPrice_, highestPrice_, 
            effectiveTime_, maturity_
        );
    }

    function getSlotDetail(uint256 slot_) public view override returns (IBondPool.SlotDetail memory) {
        return bondPool.getSlotDetail(slot_);
    }

    function getIssuerSlots(address issuer_) external view override returns (uint256[] memory slots) {
        return bondPool.getIssuerSlots(issuer_);
    }
    
    function contractURI() external view override returns (string memory) {
        return voucherDescriptor.contractURI();
    }

    function slotURI(uint256 slot_) external view override returns (string memory) {
        return voucherDescriptor.slotURI(slot_);
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "token not exists");
        return voucherDescriptor.tokenURI(tokenId_);
    }

    function getSnapshot(uint256 tokenId_)
        public
        override
        view
        returns (BondVoucherSnapshot memory snapshot)
    {
        snapshot.tokenId = tokenId_;
        snapshot.parValue = unitsInToken(tokenId_);
        snapshot.slotDetail = bondPool.getSlotDetail(voucherSlotMapping[tokenId_]);
    }

    function underlying() external view override returns (address) {
        return bondPool.underlyingToken();
    }

    function setVoucherDescriptor(address newDescriptor_) external onlyAdmin {
        require(newDescriptor_ != address(0), "newDescriptor can not be 0 address");
        emit SetDescriptor(address(voucherDescriptor), newDescriptor_);
        voucherDescriptor = IVNFTDescriptor(newDescriptor_);
    }

    function setSolver(ISolver newSolver_) external onlyAdmin {
        require(newSolver_.isSolver(), "invalid solver");
        emit SetSolver(address(solver), address(newSolver_));
        solver = newSolver_;
    }

    function voucherType() external pure override returns (Constants.VoucherType) {
        return Constants.VoucherType.BOUNDING;
    }

    function version() external pure returns (string memory) {
        return "1.0.1";
    }
}