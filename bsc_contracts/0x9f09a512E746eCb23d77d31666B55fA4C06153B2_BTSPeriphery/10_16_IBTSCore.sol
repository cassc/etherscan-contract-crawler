// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
   @title Interface of BTSCore contract
   @dev This contract is used to handle coin transferring service
   Note: The coin of following interface can be:
   Native Coin : The native coin of this chain
   Wrapped Native Coin : A tokenized ERC20 version of another native coin like ICX
*/
interface IBTSCore {
    /**
       @notice Adding another Onwer.
       @dev Caller must be an Onwer of BTP network
       @param _owner    Address of a new Onwer.
    */
    function addOwner(address _owner) external;

    /**
        @notice Get name of nativecoin
        @dev caller can be any
        @return Name of nativecoin
    */
    function getNativeCoinName() external view returns (string memory);

    /**
       @notice Removing an existing Owner.
       @dev Caller must be an Owner of BTP network
       @dev If only one Owner left, unable to remove the last Owner
       @param _owner    Address of an Owner to be removed.
    */
    function removeOwner(address _owner) external;

    /**
       @notice Checking whether one specific address has Owner role.
       @dev Caller can be ANY
       @param _owner    Address needs to verify.
    */
    function isOwner(address _owner) external view returns (bool);

    /**
       @notice Get a list of current Owners
       @dev Caller can be ANY
       @return      An array of addresses of current Owners
    */

    function getOwners() external view returns (address[] memory);

    /**
        @notice update BTS Periphery address.
        @dev Caller must be an Owner of this contract
        _btsPeriphery Must be different with the existing one.
        @param _btsPeriphery    BTSPeriphery contract address.
    */
    function updateBTSPeriphery(address _btsPeriphery) external;

    /**
        @notice set fee ratio.
        @dev Caller must be an Owner of this contract
        The transfer fee is calculated by feeNumerator/FEE_DEMONINATOR. 
        The feeNumetator should be less than FEE_DEMONINATOR
        _feeNumerator is set to `10` in construction by default, which means the default fee ratio is 0.1%.
        @param _feeNumerator    the fee numerator
    */
    function setFeeRatio(
        string calldata _name,
        uint256 _feeNumerator,
        uint256 _fixedFee
    ) external;

    /**
        @notice Registers a wrapped coin and id number of a supporting coin.
        @dev Caller must be an Owner of this contract
        _name Must be different with the native coin name.
        _symbol symbol name for wrapped coin.
        _decimals decimal number
        @param _name    Coin name. 
    */
    function register(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _feeNumerator,
        uint256 _fixedFee,
        address _addr
    ) external;

    /**
       @notice Return all supported coins names
       @dev 
       @return _names   An array of strings.
    */
    function coinNames() external view returns (string[] memory _names);

    /**
       @notice  Return an _id number of Coin whose name is the same with given _coinName.
       @dev     Return nullempty if not found.
       @return  _coinId     An ID number of _coinName.
    */
    function coinId(string calldata _coinName)
        external
        view
        returns (address _coinId);

    /**
       @notice  Check Validity of a _coinName
       @dev     Call by BTSPeriphery contract to validate a requested _coinName
       @return  _valid     true of false
    */
    function isValidCoin(string calldata _coinName)
        external
        view
        returns (bool _valid);

    /**
        @notice Get fee numerator and fixed fee
        @dev caller can be any
        @param _coinName Coin name
        @return _feeNumerator Fee numerator for given coin
        @return _fixedFee Fixed fee for given coin
    */
    function feeRatio(string calldata _coinName)
        external
        view
        returns (uint _feeNumerator, uint _fixedFee);

    /**
        @notice Return a usable/locked/refundable balance of an account based on coinName.
        @return _usableBalance the balance that users are holding.
        @return _lockedBalance when users transfer the coin, 
                it will be locked until getting the Service Message Response.
        @return _refundableBalance refundable balance is the balance that will be refunded to users.
    */
    function balanceOf(address _owner, string memory _coinName)
        external
        view
        returns (
            uint256 _usableBalance,
            uint256 _lockedBalance,
            uint256 _refundableBalance,
            uint256 _userBalance
        );

    /**
        @notice Return a list Balance of an account.
        @dev The order of request's coinNames must be the same with the order of return balance
        Return 0 if not found.
        @return _usableBalances         An array of Usable Balances
        @return _lockedBalances         An array of Locked Balances
        @return _refundableBalances     An array of Refundable Balances
    */
    function balanceOfBatch(address _owner, string[] calldata _coinNames)
        external
        view
        returns (
            uint256[] memory _usableBalances,
            uint256[] memory _lockedBalances,
            uint256[] memory _refundableBalances,
            uint256[] memory _userBalances
        );

    /**
        @notice Return a list accumulated Fees.
        @dev only return the asset that has Asset's value greater than 0
        @return _accumulatedFees An array of Asset
    */
    function getAccumulatedFees()
        external
        view
        returns (Types.Asset[] memory _accumulatedFees);

    /**
       @notice Allow users to deposit `msg.value` native coin into a BTSCore contract.
       @dev MUST specify msg.value
       @param _to  An address that a user expects to receive an amount of tokens.
    */
    function transferNativeCoin(string calldata _to) external payable;

    /**
       @notice Allow users to deposit an amount of wrapped native coin `_coinName` from the `msg.sender` address into the BTSCore contract.
       @dev Caller must set to approve that the wrapped tokens can be transferred out of the `msg.sender` account by BTSCore contract.
       It MUST revert if the balance of the holder for token `_coinName` is lower than the `_value` sent.
       @param _coinName    A given name of a wrapped coin 
       @param _value       An amount request to transfer.
       @param _to          Target BTP address.
    */
    function transfer(
        string calldata _coinName,
        uint256 _value,
        string calldata _to
    ) external;

    /**
       @notice Allow users to transfer multiple coins/wrapped coins to another chain
       @dev Caller must set to approve that the wrapped tokens can be transferred out of the `msg.sender` account by BTSCore contract.
       It MUST revert if the balance of the holder for token `_coinName` is lower than the `_value` sent.
       In case of transferring a native coin, it also checks `msg.value` with `_values[i]`
       It MUST revert if `msg.value` is not equal to `_values[i]`
       The number of requested coins MUST be as the same as the number of requested values
       The requested coins and values MUST be matched respectively
       @param _coinNames    A list of requested transferring coins/wrapped coins
       @param _values       A list of requested transferring values respectively with its coin name
       @param _to          Target BTP address.
    */
    function transferBatch(
        string[] memory _coinNames,
        uint256[] memory _values,
        string calldata _to
    ) external payable;

    /**
        @notice Reclaim the token's refundable balance by an owner.
        @dev Caller must be an owner of coin
        The amount to claim must be smaller or equal than refundable balance
        @param _coinName   A given name of coin
        @param _value       An amount of re-claiming tokens
    */
    function reclaim(string calldata _coinName, uint256 _value) external;

    /**
        @notice mint the wrapped coin.
        @dev Caller must be an BTSPeriphery contract
        Invalid _coinName will have an _id = 0. However, _id = 0 is also dedicated to Native Coin
        Thus, BTSPeriphery will check a validity of a requested _coinName before calling
        for the _coinName indicates with id = 0, it should send the Native Coin (Example: PRA) to user account
        @param _to    the account receive the minted coin
        @param _coinName    coin name
        @param _value    the minted amount   
    */
    function mint(
        address _to,
        string calldata _coinName,
        uint256 _value
    ) external;

    /**
        @notice Handle a request of Fee Gathering
        @dev    Caller must be an BTSPeriphery contract
        @param  _fa    BTP Address of Fee Aggregator 
    */
    function transferFees(string calldata _fa) external;

    /**
        @notice Handle a response of a requested service
        @dev Caller must be an BTSPeriphery contract
        @param _requester   An address of originator of a requested service
        @param _coinName    A name of requested coin
        @param _value       An amount to receive on a destination chain
        @param _fee         An amount of charged fee
    */
    function handleResponseService(
        address _requester,
        string calldata _coinName,
        uint256 _value,
        uint256 _fee,
        uint256 _rspCode
    ) external;
}