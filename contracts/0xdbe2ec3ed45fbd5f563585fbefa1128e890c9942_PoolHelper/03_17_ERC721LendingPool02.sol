// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "./VerifySignaturePool02.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IControlPlane01.sol";
import "./interfaces/ICloneFactory02.sol";
import "./interfaces/IFlashLoanReceiver.sol";
import "./PineLendingLibrary.sol";

contract ERC721LendingPool02 is
    OwnableUpgradeable,
    IERC721Receiver,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /**
     * Pool Constants
     */
    address public _valuationSigner;

    address public _supportedCollection;

    address public _controlPlane;

    address public _fundSource;

    address public _supportedCurrency;

    struct PoolParams {
        uint32 interestBPS1000000XBlock;
        uint32 collateralFactorBPS;
    }

    mapping(uint256 => PoolParams) public durationSeconds_poolParam;

    mapping(uint256 => uint256) public blockLoanAmount;
    uint256 public blockLoanLimit;

    /**
     * Pool Setup
     */

    function initialize(
        address supportedCollection,
        address valuationSigner,
        address controlPlane,
        address supportedCurrency,
        address fundSource
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _supportedCollection = supportedCollection;
        _valuationSigner = valuationSigner;
        _controlPlane = controlPlane;
        _supportedCurrency = supportedCurrency;
        _fundSource = fundSource;
        blockLoanLimit = 200000000000000000000;
    }

    function setBlockLoanLimit(uint256 bll) public onlyOwner {
        blockLoanLimit = bll;
    }

    function setDurationParam(uint256 duration, PoolParams calldata ppm)
        public
        onlyOwner
    {
        durationSeconds_poolParam[duration] = ppm;
        require(durationSeconds_poolParam[0].collateralFactorBPS == 0);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateBlockLoanAmount(uint256 loanAmount) internal {
        blockLoanAmount[block.number] += loanAmount;
        require(
            blockLoanAmount[block.number] < blockLoanLimit,
            "Amount exceed block limit"
        );
    }

    /**
     * Storage and Events
     */

    mapping(uint256 => PineLendingLibrary.LoanTerms) public _loans;

    /**
     * Loan origination
     */
    function flashLoan(
        address payable _receiver,
        address _reserve,
        uint256 _amount,
        bytes memory _params
    ) external nonReentrant {
        //check that the reserve has enough available liquidity
        uint256 availableLiquidityBefore = _reserve == address(0)
            ? address(this).balance
            : IERC20(_reserve).balanceOf(_fundSource);
        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        uint256 lenderFeeBips = durationSeconds_poolParam[0]
            .interestBPS1000000XBlock;
        //calculate amount fee
        uint256 amountFee = (_amount * (lenderFeeBips)) / (10000000000);

        //get the FlashLoanReceiver instance
        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);

        //transfer funds to the receiver
        if (_reserve == address(0)) {
            (bool success, ) = _receiver.call{value: _amount}("");
            require(success, "Flash loan: cannot send ether");
        } else {
            IERC20(_reserve).transferFrom(_fundSource, _receiver, _amount);
        }

        //execute action of the receiver
        receiver.executeOperation(_reserve, _amount, amountFee, _params);

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = _reserve == address(0)
            ? address(this).balance
            : IERC20(_reserve).balanceOf(_fundSource);

        require(
            availableLiquidityAfter == availableLiquidityBefore + (amountFee),
            "The actual balance of the protocol is inconsistent"
        );
    }

    function borrow(
        uint256[5] calldata x,
        bytes memory signature,
        bool proxy,
        address pineWallet
    ) external nonReentrant whenNotPaused returns (bool) {
        //valuation = x[0]
        //nftID = x[1]
        //uint256 loanDurationSeconds = x[2];
        //uint256 expireAtBlock = x[3];
        //uint256 borrowedAmount = x[4];
        require(
            VerifySignaturePool02.verify(
                _supportedCollection,
                x[1],
                x[0],
                x[3],
                _valuationSigner,
                signature
            ),
            "SignatureVerifier: fake valuation provided!"
        );
        require(
            IControlPlane01(_controlPlane).whitelistedIntermediaries(
                msg.sender
            ) || msg.sender == tx.origin,
            "Phishing!"
        );
        address contextUser = proxy ? tx.origin : msg.sender;
        require(
            !PineLendingLibrary.nftHasLoan(_loans[x[1]]),
            "NFT already has loan!"
        );
        uint32 maxLTVBPS = durationSeconds_poolParam[x[2]].collateralFactorBPS;
        require(maxLTVBPS > 0, "Duration not supported");

        uint256 pineMirrorID = uint256(
            keccak256(abi.encodePacked(_supportedCollection, x[1]))
        );

        if (pineWallet == (address(0))) {
            require(
                IERC721(_supportedCollection).ownerOf(x[1]) == contextUser,
                "Stealer1!"
            );
        } else {
            require(
                ICloneFactory02(
                    IControlPlane01(_controlPlane).whitelistedFactory()
                ).genuineClone(pineWallet),
                "Scammer!"
            );
            require(
                IERC721(pineWallet).ownerOf(pineMirrorID) == contextUser,
                "Stealer2!"
            );
        }

        require(block.number < x[3], "Valuation expired");
        require(
            x[4] <= (x[0] * maxLTVBPS) / 10_000,
            "Can't borrow more than max LTV"
        );
        require(
            x[4] < IERC20(_supportedCurrency).balanceOf(_fundSource),
            "not enough money"
        );

        uint32 protocolFeeBips = IControlPlane01(_controlPlane).feeBps();
        uint256 protocolFee = (x[4] * (protocolFeeBips)) / (10000);

        updateBlockLoanAmount(x[4]);

        IERC20(_supportedCurrency).transferFrom(
            _fundSource,
            msg.sender,
            x[4] - protocolFee
        );
        IERC20(_supportedCurrency).transferFrom(
            _fundSource,
            _controlPlane,
            protocolFee
        );
        _loans[x[1]] = PineLendingLibrary.LoanTerms(
            block.number,
            block.timestamp + x[2],
            durationSeconds_poolParam[x[2]].interestBPS1000000XBlock,
            maxLTVBPS,
            x[4],
            0,
            0,
            0,
            contextUser
        );

        if (pineWallet == (address(0))) {
            IERC721(_supportedCollection).transferFrom(
                contextUser,
                address(this),
                x[1]
            );
        } else {
            IERC721(pineWallet).transferFrom(
                contextUser,
                address(this),
                pineMirrorID
            );
        }

        emit PineLendingLibrary.LoanInitiated(
            contextUser,
            _supportedCollection,
            x[1],
            _loans[x[1]]
        );
        return true;
    }

    /**
     * Repay
     */

    // repay change loan terms, renew loan start, fix interest to borrowed amount, dont renew loan expiry
    function repay(
        uint256 nftID,
        uint256 repayAmount,
        address pineWallet
    ) external nonReentrant whenNotPaused returns (bool) {
        uint256 pineMirrorID = uint256(
            keccak256(abi.encodePacked(_supportedCollection, nftID))
        );
        require(
            PineLendingLibrary.nftHasLoan(_loans[nftID]),
            "NFT does not have active loan"
        );
        require(
            IERC20(_supportedCurrency).transferFrom(
                msg.sender,
                address(this),
                repayAmount
            ),
            "fund transfer unsuccessful"
        );
        PineLendingLibrary.LoanTerms memory oldLoanTerms = _loans[nftID];

        if (repayAmount >= PineLendingLibrary.outstanding(_loans[nftID])) {
            require(
                IERC20(_supportedCurrency).transfer(
                    msg.sender,
                    repayAmount - PineLendingLibrary.outstanding(_loans[nftID])
                ),
                "exceed amount transfer unsuccessful"
            );
            repayAmount = PineLendingLibrary.outstanding(_loans[nftID]);
            _loans[nftID].returnedWei = _loans[nftID].borrowedWei;
            if (pineWallet == address(0)) {
                IERC721(_supportedCollection).transferFrom(
                    address(this),
                    _loans[nftID].borrower,
                    nftID
                );
            } else {
                require(
                    ICloneFactory02(
                        IControlPlane01(_controlPlane).whitelistedFactory()
                    ).genuineClone(pineWallet),
                    "Scammer!"
                );
                IERC721(pineWallet).transferFrom(
                    address(this),
                    _loans[nftID].borrower,
                    pineMirrorID
                );
            }
            clearLoanTerms(nftID);
        } else {
            // lump in interest
            _loans[nftID].accuredInterestWei +=
                ((block.number - _loans[nftID].loanStartBlock) *
                    (_loans[nftID].borrowedWei - _loans[nftID].returnedWei) *
                    _loans[nftID].interestBPS1000000XBlock) /
                10000000000;
            uint256 outstandingInterest = _loans[nftID].accuredInterestWei -
                _loans[nftID].repaidInterestWei;
            if (repayAmount > outstandingInterest) {
                _loans[nftID].repaidInterestWei = _loans[nftID]
                    .accuredInterestWei;
                _loans[nftID].returnedWei += (repayAmount -
                    outstandingInterest);
            } else {
                _loans[nftID].repaidInterestWei += repayAmount;
            }
            // restart interest calculation
            _loans[nftID].loanStartBlock = block.number;
        }
        require(
            IERC20(_supportedCurrency).transferFrom(
                address(this),
                _fundSource,
                IERC20(_supportedCurrency).balanceOf(address(this))
            ),
            "fund transfer unsuccessful"
        );
        emit PineLendingLibrary.LoanTermsChanged(
            _loans[nftID].borrower,
            _supportedCollection,
            nftID,
            oldLoanTerms,
            _loans[nftID]
        );
        return true;
    }

    /**
     * Admin functions
     */

    function withdraw(uint256 amount) external onlyOwner {
        (bool success, ) = owner().call{value: amount}("");
        require(success, "cannot send ether");
    }

    function withdrawERC20(address currency, uint256 amount)
        external
        onlyOwner
    {
        IERC20(currency).transfer(owner(), amount);
    }

    function withdrawERC721(
        address collection,
        uint256 nftID,
        address target,
        bool liquidation
    ) external {
        require(msg.sender == _controlPlane, "not control plane");
        if ((target == _supportedCollection) && liquidation) {
            PineLendingLibrary.LoanTerms memory lt = _loans[nftID];
            emit PineLendingLibrary.Liquidation(
                lt.borrower,
                _supportedCollection,
                nftID,
                block.timestamp,
                tx.origin
            );
            clearLoanTerms(nftID);
        }
        IERC721(collection).transferFrom(address(this), target, nftID);
    }

    function clearLoanTerms(uint256 nftID) internal {
        _loans[nftID] = PineLendingLibrary.LoanTerms(
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            address(0)
        );
    }
}