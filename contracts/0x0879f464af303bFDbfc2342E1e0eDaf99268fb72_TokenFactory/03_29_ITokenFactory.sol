// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@dlsl/dev-modules/pool-contracts-registry/ProxyBeacon.sol";

interface ITokenFactory {
    /**
     * @notice The structure that stores information about deploy token contract params
     * @param tokenContractId the deployed token contract ID
     * @param tokenName the token name of the deployed contract
     * @param tokenSymbol the token symbol of the deployed contract
     * @param pricePerOneToken the price per one token
     * @param voucherTokenContract the address of the voucher token contract
     * @param voucherTokensAmount the amount of voucher tokens
     */
    struct DeployTokenContractParams {
        uint256 tokenContractId;
        string tokenName;
        string tokenSymbol;
        uint256 pricePerOneToken;
        address voucherTokenContract;
        uint256 voucherTokensAmount;
    }

    /**
     * @notice The structure that stores base information about the TokenContract
     * @param tokenContractAddr the address of the TokenContract
     * @param pricePerOneToken the price per one token in USD
     */
    struct BaseTokenContractInfo {
        address tokenContractAddr;
        uint256 pricePerOneToken;
    }

    /**
     * @notice The structure that stores information about user's NFTs
     * @param tokenContractAddr the address of the TokenContract
     * @param tokenIDs the array of the user token IDs
     */
    struct UserNFTsInfo {
        address tokenContractAddr;
        uint256[] tokenIDs;
    }

    /**
     * @notice This event is emitted when the URI of the base token contracts has been updated
     * @param newBaseTokenContractsURI the new base token contracts URI string
     */
    event BaseTokenContractsURIUpdated(string newBaseTokenContractsURI);

    /**
     * @notice This event is emitted when the list of admins is updated
     * @param adminsToUpdate the array of addresses of admins to update
     * @param isAdding flag indicating that admins have been added or removed
     */
    event AdminsUpdated(address[] adminsToUpdate, bool isAdding);

    /**
     * @notice This event is emitted during the creation of a new TokenContract
     * @param newTokenContractAddr the address of the created token contract
     * @param tokenContractParams struct with the token contract params
     */
    event TokenContractDeployed(
        address newTokenContractAddr,
        DeployTokenContractParams tokenContractParams
    );

    /**
     * @notice The function for initializing contract variables
     * @param adminsArr_ the initial admins array
     * @param baseTokenContractsURI_ the initial base token contracts URI string
     * @param priceDecimals_ the price decimals value
     */
    function __TokenFactory_init(
        address[] memory adminsArr_,
        string memory baseTokenContractsURI_,
        uint8 priceDecimals_
    ) external;

    /**
     * @notice The function to update the baseTokenContractsURI parameter
     * @dev Only OWNER can call this function
     * @param baseTokenContractsURI_ the new base token contracts URI value
     */
    function setBaseTokenContractsURI(string memory baseTokenContractsURI_) external;

    /**
     * @notice The function to update the TokenContract implementation
     * @dev Only OWNER can call this function
     * @param newImplementation_ the new TokenContract implementation
     */
    function setNewImplementation(address newImplementation_) external;

    /**
     * @notice The function to update the admins list
     * @dev Only OWNER can call this function
     * @param adminsToUpdate_ the array of admins to update
     * @param isAdding_ flag indicating that admins have been added or removed
     */
    function updateAdmins(address[] calldata adminsToUpdate_, bool isAdding_) external;

    /**
     * @notice The function for deploying new instances of TokenContract
     * @param params_ structure with the deploy token contract params
     * @param r_ the r parameter of the ECDSA signature
     * @param s_ the s parameter of the ECDSA signature
     * @param v_ the v parameter of the ECDSA signature
     */
    function deployTokenContract(
        DeployTokenContractParams calldata params_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) external;

    /**
     * @notice The function that returns the address of the token contracts beacon
     * @return token contracts beacon address
     */
    function tokenContractsBeacon() external view returns (ProxyBeacon);

    /**
     * @notice The function that returns the price decimals value
     * @return price decimals value
     */
    function priceDecimals() external view returns (uint8);

    /**
     * @notice The function that returns the base token contracts URI string
     * @return base token contracts URI string
     */
    function baseTokenContractsURI() external view returns (string memory);

    /**
     * @notice The function that returns the address of the token contract by index
     * @param tokenContractId_ the needed token contracts ID
     * @return address of the token contract
     */
    function tokenContractByIndex(uint256 tokenContractId_) external view returns (address);

    /**
     * @notice The function that returns basic token contracts information for passed addresses
     * @param tokenContractsArr_ the array of addresses for which you want to get information
     * @return tokenContractsInfoArr_ athe array of BaseTokenContractInfo structures with basic information
     */
    function getBaseTokenContractsInfo(address[] memory tokenContractsArr_)
        external
        view
        returns (BaseTokenContractInfo[] memory tokenContractsInfoArr_);

    /**
     * @notice The function that returns information about the user's NFT
     * @param userAddr_ the address of the user you want to get information from
     * @return userNFTsInfoArr_ the array of BaseTokenContractInfo structures with basic information
     */
    function getUserNFTsInfo(address userAddr_)
        external
        view
        returns (UserNFTsInfo[] memory userNFTsInfoArr_);

    /**
     * @notice The function that returns the current admins array
     * @return admins array
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @notice The function to check if the passed address is an admin
     * @param userAddr_ the address of the user you want to get information from
     * @return true if the passed address is an admin address, false otherwise
     */
    function isAdmin(address userAddr_) external view returns (bool);

    /**
     * @notice The function that returns the address of the TokenContracts implementation
     * @return address of the TokenContract implementation
     */
    function getTokenContractsImpl() external view returns (address);

    /**
     * @notice The function that returns the total TokenContracts count
     * @return total TokenContracts count
     */
    function getTokenContractsCount() external view returns (uint256);

    /**
     * @notice The function for getting addresses of token contracts with pagination
     * @param offset_ the offset for pagination
     * @param limit_ the maximum number of elements for
     * @return array with the addresses of the token contracts
     */
    function getTokenContractsPart(uint256 offset_, uint256 limit_)
        external
        view
        returns (address[] memory);
}