/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

pragma solidity ^0.5.0;

contract ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns (address);
}


/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */



contract ERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(bytes32 => bool) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/) // Comments to avoid compilation warnings for unused variables.
    external
    view
    returns(bytes32)
  {
    if(_interfaceHashes[interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  function _setInterface(string memory interfaceLabel) internal {
    _interfaceHashes[keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */


/**
 * @title Holdable ERC20 Token Interface.
 * @dev like approve except the tokens can't be spent by the sender while they are on hold.
 */
interface IERC20HoldableToken {
    enum HoldStatusCode {Nonexistent, Held, Executed, Released}

    event NewHold(
        bytes32 indexed holdId,
        address indexed recipient,
        address indexed notary,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    );
    event ExecutedHold(
        bytes32 indexed holdId,
        bytes32 lockPreimage,
        address recipient
    );
    event ReleaseHold(bytes32 indexed holdId, address sender);

    /**
     @notice Called by the sender to hold some tokens for a recipient that the sender can not release back to themself until after the expiration date.
     @param recipient optional account the tokens will be transferred to on execution. If a zero address, the recipient must be specified on execution of the hold.
     @param notary account that can execute the hold. Typically the recipient but can be a third party or a smart contact.
     @param amount of tokens to be transferred to the recipient on execution. Must be a non zero amount.
     @param expirationDateTime UNIX epoch seconds the held amount can be released back to the sender by the sender. Past dates are allowed.
     @param lockHash optional keccak256 hash of a lock preimage. An empty hash will not enforce the hash lock when the hold is executed.
     @return a unique identifier for the hold.
     */
    function hold(
        address recipient,
        address notary,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    ) external returns (bytes32 holdId);

    /**
     @notice Called by the notary to transfer the held tokens to the set at the hold recipient if there is no hash lock.
     @param holdId a unique identifier for the hold.
     */
    function executeHold(bytes32 holdId) external;

    /**
     @notice Called by the notary to transfer the held tokens to the recipient that was set at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a keccak256 hash
     */
    function executeHold(bytes32 holdId, bytes32 lockPreimage) external;

    /**
     @notice Called by the notary to transfer the held tokens to the recipient if no recipient was specified at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a keccak256 hash
     @param recipient the account the tokens will be transferred to on execution.
     */
    function executeHold(
        bytes32 holdId,
        bytes32 lockPreimage,
        address recipient
    ) external;

    /**
     @notice Called by the notary at any time or the sender after the expiration date to release the held tokens back to the sender.
     @param holdId a unique identifier for the hold.
     */
    function releaseHold(bytes32 holdId) external;

    /**
     @notice Amount of tokens owned by an account that are available for transfer. That is, the gross balance less any held tokens.
     @param account owner of the tokensß
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     @notice Amount of tokens owned by an account that are held pending execution or release.
     @param account owner of the tokens
     */
    function holdBalanceOf(address account) external view returns (uint256);

    /**
     @notice Total amount of tokens owned by an account including all the held tokens pending execution or release.
     @param account owner of the tokens
     */
    function grossBalanceOf(address account) external view returns (uint256);

    function totalSupplyOnHold() external view returns (uint256);

    /**
     @param holdId a unique identifier for the hold.
     @return hold status code.
     */
    function holdStatus(bytes32 holdId) external view returns (HoldStatusCode);
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */







interface HoldableERC1400TokenExtension {
    enum HoldStatusCode {
        Nonexistent,
        Ordered,
        Executed,
        ExecutedAndKeptOpen,
        ReleasedByNotary,
        ReleasedByPayee,
        ReleasedOnExpiration
    }

    function executeHold(
        address token,
        bytes32 holdId,
        uint256 value,
        bytes32 lockPreimage
    ) external;

    function retrieveHoldData(address token, bytes32 holdId) external view returns (
        bytes32 partition,
        address sender,
        address recipient,
        address notary,
        uint256 value,
        uint256 expiration,
        bytes32 secretHash,
        bytes32 secret,
        HoldStatusCode status
    );
}

/**
 * @title DVPHoldableLockable
 * @notice Facilitates the atomic settlement of ERC20 and ERC1400 Holdable Tokens.
 */
contract DVPHoldableLockable is ERC1820Client, ERC1820Implementer {
    string internal constant DVP_HOLDABLE_LOCKABLE = "DVPHoldableLockable";
    
    string internal constant ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";

    enum Standard {Undefined, HoldableERC20, HoldableERC1400}

    event ExecuteHolds(
        address indexed token1,
        bytes32 token1HoldId,
        address indexed token2,
        bytes32 token2HoldId,
        bytes32 preimage,
        address token1Recipient,
        address token2Recipient
    );

    /**
    @dev Include token events so they can be parsed by Ethereum clients from the settlement transactions.
     */
    // Holdable
    event ExecutedHold(bytes32 indexed holdId, bytes32 lockPreimage);
    event ExecutedHold(
        bytes32 indexed holdId,
        bytes32 lockPreimage,
        address recipient
    );
    // ERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    // ERC1400
    event TransferByPartition(
        bytes32 indexed fromPartition,
        address operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );
    event CreateNote(
        address indexed owner,
        bytes32 indexed noteHash,
        bytes metadata
    );
    event DestroyNote(address indexed owner, bytes32 indexed noteHash);

    /**
     * [DVP CONSTRUCTOR]
     */
    constructor() public {
        ERC1820Implementer._setInterface(DVP_HOLDABLE_LOCKABLE);
    }

    /**
     @notice Execute holds where the hold recipients are already known
     @param token1 contract address of the first token
     @param token1HoldId 32 byte hold identified from the first token
     @param tokenStandard1 Standard enum indicating if the first token is HoldableERC20 or HoldableERC1400
     @param token2 contract address of the second token
     @param token2HoldId 32 byte hold identified from the second token
     @param tokenStandard2 Standard enum indicating if the second token is HoldableERC20 or HoldableERC1400
     @param preimage optional preimage of the SHA256 hash used to lock both the token holds. This can be a zero address if no lock hash was used.
     */
    function executeHolds(
        address token1,
        bytes32 token1HoldId,
        Standard tokenStandard1,
        address token2,
        bytes32 token2HoldId,
        Standard tokenStandard2,
        bytes32 preimage
    ) public {
        _executeHolds(
            token1,
            token1HoldId,
            tokenStandard1,
            token2,
            token2HoldId,
            tokenStandard2,
            preimage,
            address(0),
            address(0)
        );
    }

    /**
     @notice Execute holds where the hold recipients are only known at execution.
     @param token1 contract address of the first token
     @param token1HoldId 32 byte hold identified from the first token
     @param tokenStandard1 Standard enum indicating if the first token is HoldableERC20 or HoldableERC1400
     @param token2 contract address of the second token
     @param token2HoldId 32 byte hold identified from the second token
     @param tokenStandard2 Standard enum indicating if the second token is HoldableERC20 or HoldableERC1400
     @param preimage optional preimage of the SHA256 hash used to lock both the token holds. This can be a zero address if no lock hash was used.
     @param token1Recipient address of the recipient of the first tokens.
     @param token2Recipient address of the recipient of the second tokens.
     */
    function executeHolds(
        address token1,
        bytes32 token1HoldId,
        Standard tokenStandard1,
        address token2,
        bytes32 token2HoldId,
        Standard tokenStandard2,
        bytes32 preimage,
        address token1Recipient,
        address token2Recipient
    ) public {
        _executeHolds(
            token1,
            token1HoldId,
            tokenStandard1,
            token2,
            token2HoldId,
            tokenStandard2,
            preimage,
            token1Recipient,
            token2Recipient
        );
    }

    /**
     @dev this is in a separate function to work around stack too deep problems
     */
    function _executeHolds(
        address token1,
        bytes32 token1HoldId,
        Standard tokenStandard1,
        address token2,
        bytes32 token2HoldId,
        Standard tokenStandard2,
        bytes32 preimage,
        address token1Recipient,
        address token2Recipient
    ) internal {
        // Token 1
        if (tokenStandard1 == Standard.HoldableERC20) {
            _executeERC20Hold(token1, token1HoldId, preimage, token1Recipient);
        } else if (tokenStandard1 == Standard.HoldableERC1400) {
            _executeERC1400Hold(
                token1,
                token1HoldId,
                preimage
            );
        } else {
            revert("invalid token standard");
        }

        // Token 2
        if (tokenStandard2 == Standard.HoldableERC20) {
            _executeERC20Hold(token2, token2HoldId, preimage, token2Recipient);
        } else if (tokenStandard2 == Standard.HoldableERC1400) {
            _executeERC1400Hold(
                token2,
                token2HoldId,
                preimage
            );
        } else {
            revert("invalid token standard");
        }

        emit ExecuteHolds(
            token1,
            token1HoldId,
            token2,
            token2HoldId,
            preimage,
            token1Recipient,
            token2Recipient
        );
    }

    function _executeERC20Hold(
        address token,
        bytes32 tokenHoldId,
        bytes32 preimage,
        address tokenRecipient
    ) internal {
        require(token != address(0), "token can not be a zero address");

        if (tokenRecipient == address(0)) {
            IERC20HoldableToken(token).executeHold(tokenHoldId, preimage);
        } else {
            IERC20HoldableToken(token).executeHold(
                tokenHoldId,
                preimage,
                tokenRecipient
            );
        }
    }

    function _executeERC1400Hold(
        address token,
        bytes32 tokenHoldId,
        bytes32 preimage
    ) internal {
        require(token != address(0), "token can not be a zero address");

        address tokenExtension = interfaceAddr(token, ERC1400_TOKENS_VALIDATOR);
        require(
            tokenExtension != address(0),
            "token has no holdable token extension"
        );

        uint256 holdValue;
        (,,,,holdValue,,,,) = HoldableERC1400TokenExtension(tokenExtension).retrieveHoldData(token, tokenHoldId);

        HoldableERC1400TokenExtension(tokenExtension).executeHold(
            token,
            tokenHoldId,
            holdValue,
            preimage
        );
    }
}