/**
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.13;

interface IKomethAppImplementation {
    enum Stage {
        Pause,
        Private,
        Public,
        Mint,
        Ended
    }

    struct PublicSale {
        uint256 price;
        uint256 txLimit;
        uint256 walletLimit;
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
     * @param _quantity Amount of item to be minted
     * @param _txLimit Limit amount of item that can be minted in a transaction
     * @param _walletLimit Limit amount of item that can be minted in a wallet
     * @param _deadline Time limit of how long user can mint with the given signature
     * @param _kind The index of private sale.
     * @param _signature The signature that has been generated.
     */
    function privateSaleMint(
        uint256 _quantity,
        uint256 _txLimit,
        uint256 _walletLimit,
        uint256 _deadline,
        uint256 _kind,
        bytes calldata _signature
    ) external payable;

    /**
     * @dev Mints the token through private sale phase by verifying the given signature to given address.
     *
     * @param _quantity Amount of item to be minted
     * @param _txLimit Limit amount of item that can be minted in a transaction
     * @param _walletLimit Limit amount of item that can be minted in a wallet
     * @param _deadline Time limit of how long user can mint with the given signature
     * @param _recipient Given address
     * @param _kind The index of private sale.
     * @param _signature The signature that has been generated.
     */
    function delegateMint(
        uint256 _quantity,
        uint256 _txLimit,
        uint256 _walletLimit,
        uint256 _deadline,
        address _recipient,
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
     * @param _price New price value.
     */
    function setPrivateSalePrice(uint256 _kind, uint256 _price) external;

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