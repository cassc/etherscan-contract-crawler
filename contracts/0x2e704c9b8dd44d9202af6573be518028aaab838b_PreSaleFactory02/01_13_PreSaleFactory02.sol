// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "../interfaces/IPool02.sol";
import "./PreSalePool02.sol";
import "../libraries/Ownable.sol";
import "../libraries/Pausable.sol";
import "../libraries/Initializable.sol";

contract PreSaleFactory02 is Ownable, Pausable, Initializable {
    // Array of created Pools Address
    address[] public allPools;
    // Mapping from User token. From tokens to array of created Pools for token
    mapping(address => mapping(address => address[])) public getPools;

    event PresalePoolCreated(
        address registedBy,
        address indexed token,
        address indexed pool,
        uint256 poolId
    );

    function initialize() external initializer {
        paused = false;
        owner = msg.sender;
    }

    /**
     * @notice Get the number of all created pools
     * @return Return number of created pools
     */
    function allPoolsLength() public view returns (uint256) {
        return allPools.length;
    }

    /**
     * @notice Get the created pools by token address
     * @dev User can retrieve their created pool by address of tokens
     * @param _creator Address of created pool user
     * @param _token Address of token want to query
     * @return Created PreSalePool Address
     */
    function getCreatedPoolsByToken(address _creator, address _token)
        public
        view
        returns (address[] memory)
    {
        return getPools[_creator][_token];
    }

    /**
     * @notice Retrieve number of pools created for specific token
     * @param _creator Address of created pool user
     * @param _token Address of token want to query
     * @return Return number of created pool
     */
    function getCreatedPoolsLengthByToken(address _creator, address _token)
        public
        view
        returns (uint256)
    {
        return getPools[_creator][_token].length;
    }

    /**
     * @notice Register ICO PreSalePool for tokens
     * @dev To register, you MUST have an ERC20 token
     * @param _token address of ERC20 token
     * @param _offeredCurrency Address of offered token
     * @param _offeredCurrencyDecimals Decimals of offered token
     * @param _offeredRate Conversion rate for buy token. tokens = value * rate
     * @param _wallet Address of funding ICO wallets. Sold tokens in eth will transfer to this address
     * @param _signer Address of funding ICO wallets. Sold tokens in eth will transfer to this address
     */
    function registerPool(
        address _token,
        address _offeredCurrency,
        uint256 _offeredCurrencyDecimals,
        uint256 _offeredRate,
        uint256 _taxRate,
        address _wallet,
        address _signer
    ) external whenNotPaused returns (address pool) {
        require(_token != address(0), "ICOFactory::ZERO_ADDRESS");
        require(_wallet != address(0), "ICOFactory::ZERO_ADDRESS");
        require(_offeredRate != 0, "ICOFactory::ZERO_OFFERED_RATE");
        bytes memory bytecode = type(PreSalePool02).creationCode;
        uint256 tokenIndex = getCreatedPoolsLengthByToken(msg.sender, _token);
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, _token, tokenIndex)
        );
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IPool02(pool).initialize(
            _token,
            _offeredCurrency,
            _offeredRate,
            _offeredCurrencyDecimals,
            _taxRate,
            _wallet,
            _signer
        );
        getPools[msg.sender][_token].push(pool);
        allPools.push(pool);

        emit PresalePoolCreated(msg.sender, _token, pool, allPools.length - 1);
    }
}