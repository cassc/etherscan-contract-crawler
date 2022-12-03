/**
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.13;

interface IGaspackAppImplementation {
    enum Stage {
        Pause,
        Private,
        Public,
        Mint,
        Ended
    }

    struct PublicSale {
        uint256 price;
        uint256 quantity;
        uint256 txLimit;
        uint256 walletLimit;
    }

    struct PrivateSale {
        uint256 price;
        uint256 quantity;
        uint256 txLimit;
        uint256 walletLimit;
        uint256 deadline;
    }

    /**
     * @dev Mints the token with desired amounts and addresses
     *
     * Calling condition:
     * - The caller must be owner of the contract or the one
     *   who has the right role.
     *
     * @param _to An array of addresses.
     * @param _amount An array of amounts. Array length must be same as _to param.
     */
    function mintTo(
        address[] calldata _to,
        uint256[] calldata _amount
    ) external;

    /**
     * @dev Mints the token through private sale phase by verifying the given signature.
     *
     * @param _privateSale The {PrivateSale} struct configuration.
     * @param _nonce User nonce.
     * @param _kind The index of private sale.
     * @param _signature The signature that has been generated.
     */
    function privateSaleMint(
        PrivateSale memory _privateSale,
        uint256 _nonce,
        uint256 _kind,
        bytes calldata _signature
    ) external payable;

    /**
     * @dev Mints the token through public sale phase.
     *
     * @param _quantity Amount of token to be minted.
     */
    function publicSaleMint(uint256 _quantity) external payable;

    /**
     * @dev Mints the token through public sale phase.
     *
     * @param _kind The private sale index.
     * @param _privateSale The struct of PrivateSale that are going to be used.
     */
    function setPrivateSale(
        uint256 _kind,
        PrivateSale memory _privateSale
    ) external;

    /**
     * @dev Updates the contract stage
     *
     * Calling condition:
     * - The caller must be the owner of the contract.
     *
     * @param _stage The new stage.
     */
    function setStage(Stage _stage) external;

    /**
     * @dev Updates the configured signer.
     *
     * Calling condition:
     * - The caller must be the owner of the contract.
     *
     * @param _signer The new signer.
     */
    function setSigner(address _signer) external;

    /**
     * @dev Updates the configured base URI.
     *
     * Calling condition:
     * - The caller must be the owner of the contract.
     *
     * @param _baseURI The new base URI.
     */
    function setBaseURI(string calldata _baseURI) external;

    /**
     * @dev Updates the configured minter address.
     *
     * Calling condition:
     * - The caller must be the owner of the contract.
     *
     * @param _authorizedAddress New authorized address
     * @param _value Access value
     */
    function setAuthorizedAddress(
        address _authorizedAddress,
        bool _value
    ) external;

    /**
     * @dev Burns the token with inputted id.
     *
     * Calling condition:
     * - The caller must be the one who has the right role.
     *
     * @param _tokenId ID of the token.
     */
    function burn(uint256 _tokenId) external;

    /**
     * @dev Withdraw all the contract balance.
     *
     * Calling condition:
     * - The caller must be owner of the contract.
     */
    function withdrawAll() external;
}