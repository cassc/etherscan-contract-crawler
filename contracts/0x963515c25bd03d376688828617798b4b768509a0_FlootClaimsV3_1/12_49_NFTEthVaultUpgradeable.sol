// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */



contract NFTEthVaultUpgradeable is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalReleased;
    address public baseToken;
    
    mapping(uint => uint256) private _released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor() payable {
    }

     // solhint-disable-next-line
    function __nftVault_init(address _baseToken) public initializer {
        __Context_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __nftVault_init_unchained();
        baseToken = _baseToken;
    }

     // solhint-disable-next-line
    function __nftVault_init_unchained() internal initializer {
    }
    
    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint doji) public view returns (uint256) {
        return _released[doji];
    }

    function expectedRelease(uint doji) public view returns (uint256) {
        require(IERC721EnumerableUpgradeable(baseToken).totalSupply() > 0, "PaymentSplitter: Doji has no shares");
        require(doji <= IERC721EnumerableUpgradeable(baseToken).totalSupply(), "The Token hasn't been minted yet");
        uint256 totalReceived = address(this).balance + _totalReleased;
        if (totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() <= _released[doji]) {
            return 0;
        }
        uint256 payment = totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() - _released[doji];

        return payment;
    }

    /**
     * @dev Triggers a transfer to `doji` holder of the amount of Ether they are owed, according to their percentage of the
     * total shares (1/totalSupply) and their previous withdrawals.
     */
    function release(uint doji) public virtual nonReentrant {
        require(IERC721EnumerableUpgradeable(baseToken).totalSupply() > 0, "PaymentSplitter: Doji has no shares");
        require(IERC721EnumerableUpgradeable(baseToken).ownerOf(doji) == _msgSender());

        uint256 totalReceived = address(this).balance + _totalReleased;

        require(totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() > _released[doji], "PaymentSplitter: doji is not due payment");

        uint256 payment = totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() - _released[doji];

        require(payment > 0, "PaymentSplitter: doji is not due payment");

        _released[doji] = _released[doji] + payment;
        _totalReleased = _totalReleased + payment;
        address payable account = payable(IERC721EnumerableUpgradeable(baseToken).ownerOf(doji));
        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to owner in case of emergency
     */
    function rescueEther() public onlyOwner  {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }

    function changeBaseToken(address _baseToken) public onlyOwner  {
        require(_baseToken != address(0));
        baseToken = _baseToken;
    }
}