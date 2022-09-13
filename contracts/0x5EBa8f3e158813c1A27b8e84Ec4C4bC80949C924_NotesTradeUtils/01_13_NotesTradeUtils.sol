// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/KeysMapping.sol";
import "../interfaces/IAllowedERC20s.sol";
import "../interfaces/IDispatcher.sol";
import "../interfaces/ILoanManager.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NotesTradeUtils {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    IDispatcher public hub;

    bytes32 public immutable LOAN_COORDINATOR;

    constructor(address _dispatcher, bytes32 _loanCoordinatorKey) {
        hub = IDispatcher(_dispatcher);
        LOAN_COORDINATOR = _loanCoordinatorKey;
    }

    mapping(address => mapping(uint256 => bool)) private _nonceHasBeenUsedForUser;

    function disableNonceForTrade(uint256 _nonce) external {
        require(!_nonceHasBeenUsedForUser[msg.sender][_nonce], "Invalid nonce");
        _nonceHasBeenUsedForUser[msg.sender][_nonce] = true;
    }

    function hasNonceBeenUsed(address _user, uint256 _nonce) external view returns (bool) {
        return _nonceHasBeenUsedForUser[_user][_nonce];
    }

    function sellObligationReceipt(
        address _tradeERC20,
        uint256 _nftId,
        uint256 _erc20Amount,
        address _buyer,
        uint256 _buyerNonce,
        uint256 _expiry,
        bytes memory _buyerSignature
    ) external {
        require(!_nonceHasBeenUsedForUser[_buyer][_buyerNonce], "Buyer nonce invalid");
        _nonceHasBeenUsedForUser[_buyer][_buyerNonce] = true;
        ILoanManager loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        address obligationReceipt = loanCoordinator.obligationReceiptToken();
        require(
            isValidTradeSignature(
                _tradeERC20,
                obligationReceipt,
                _nftId,
                _erc20Amount,
                _buyer,
                _buyerNonce,
                _expiry,
                _buyerSignature
            ),
            "Trade signature is invalid"
        );
        trade(_tradeERC20, obligationReceipt, _nftId, _erc20Amount, msg.sender, _buyer);
    }

    function buyObligationReceipt(
        address _tradeERC20,
        uint256 _nftId,
        uint256 _erc20Amount,
        address _seller,
        uint256 _sellerNonce,
        uint256 _expiry,
        bytes memory _sellerSignature
    ) external {
        require(!_nonceHasBeenUsedForUser[_seller][_sellerNonce], "Seller nonce invalid");
        _nonceHasBeenUsedForUser[_seller][_sellerNonce] = true;
        ILoanManager loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        address obligationReceipt = loanCoordinator.obligationReceiptToken();
        require(
            isValidTradeSignature(
                _tradeERC20,
                obligationReceipt,
                _nftId,
                _erc20Amount,
                _seller,
                _sellerNonce,
                _expiry,
                _sellerSignature
            ),
            "Trade signature is invalid"
        );
        trade(_tradeERC20, obligationReceipt, _nftId, _erc20Amount, _seller, msg.sender);
    }

    function sellPromissoryNote(
        address _tradeERC20,
        uint256 _nftId,
        uint256 _erc20Amount,
        address _buyer,
        uint256 _buyerNonce,
        uint256 _expiry,
        bytes memory _buyerSignature
    ) external {
        require(!_nonceHasBeenUsedForUser[_buyer][_buyerNonce], "Buyer nonce invalid");
        _nonceHasBeenUsedForUser[_buyer][_buyerNonce] = true;
        ILoanManager loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        address promissoryNote = loanCoordinator.promissoryNoteToken();
        require(
            isValidTradeSignature(
                _tradeERC20,
                promissoryNote,
                _nftId,
                _erc20Amount,
                _buyer,
                _buyerNonce,
                _expiry,
                _buyerSignature
            ),
            "Trade signature is invalid"
        );
        trade(_tradeERC20, promissoryNote, _nftId, _erc20Amount, msg.sender, _buyer);
    }

    function buyPromissoryNote(
        address _tradeERC20,
        uint256 _nftId,
        uint256 _erc20Amount,
        address _seller,
        uint256 _sellerNonce,
        uint256 _expiry,
        bytes memory _sellerSignature
    ) external {
        require(!_nonceHasBeenUsedForUser[_seller][_sellerNonce], "Seller nonce invalid");
        _nonceHasBeenUsedForUser[_seller][_sellerNonce] = true;
        ILoanManager loanCoordinator = ILoanManager(hub.getContract(LOAN_COORDINATOR));
        address promissoryNote = loanCoordinator.promissoryNoteToken();
        require(
            isValidTradeSignature(
                _tradeERC20,
                promissoryNote,
                _nftId,
                _erc20Amount,
                _seller,
                _sellerNonce,
                _expiry,
                _sellerSignature
            ),
            "Trade signature is invalid"
        );
        trade(_tradeERC20, promissoryNote, _nftId, _erc20Amount, _seller, msg.sender);
    }

    function trade(
        address _tradeERC20,
        address _tradeNft,
        uint256 _nftId,
        uint256 _erc20Amount,
        address _seller,
        address _buyer
    ) internal {
        require(
            IAllowedERC20s(hub.getContract(KeysMapping.PERMITTED_ERC20S)).isERC20Permitted(_tradeERC20),
            "Currency denomination is not permitted"
        );
        IERC20(_tradeERC20).safeTransferFrom(_buyer, _seller, _erc20Amount);
        IERC721(_tradeNft).safeTransferFrom(_seller, _buyer, _nftId);
    }

    function isValidTradeSignature(
        address _tradeERC20,
        address _tradeNft,
        uint256 _nftId,
        uint256 _erc20Amount,
        address _accepter,
        uint256 _accepterNonce,
        uint256 _expiry,
        bytes memory _accepterSignature
    ) public view returns (bool) {
        require(block.timestamp <= _expiry, "Trade Signature has expired");
        if (_accepter == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(
                    _tradeERC20,
                    _tradeNft,
                    _nftId,
                    _erc20Amount,
                    _accepter,
                    _accepterNonce,
                    _expiry,
                    getChainID()
                )
            );

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

            return (messageWithEthSignPrefix.recover(_accepterSignature) == _accepter);
        }
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}