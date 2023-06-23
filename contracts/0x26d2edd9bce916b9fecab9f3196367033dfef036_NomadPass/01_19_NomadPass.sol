// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";


// ███╗   ██╗ ██████╗ ███╗   ███╗ █████╗ ██████╗     ██████╗ ██╗    ██╗   ██╗██████╗     ███╗   ███╗██╗███╗   ██╗████████╗    ██████╗  █████╗ ███████╗███████╗██████╗  ██████╗ ██████╗ ████████╗
// ████╗  ██║██╔═══██╗████╗ ████║██╔══██╗██╔══██╗    ██╔══██╗██║    ██║   ██║██╔══██╗    ████╗ ████║██║████╗  ██║╚══██╔══╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝
// ██╔██╗ ██║██║   ██║██╔████╔██║███████║██║  ██║    ██████╔╝██║    ██║   ██║██║  ██║    ██╔████╔██║██║██╔██╗ ██║   ██║       ██████╔╝███████║███████╗███████╗██████╔╝██║   ██║██████╔╝   ██║
// ██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██║██║  ██║    ██╔══██╗██║    ╚██╗ ██╔╝██║  ██║    ██║╚██╔╝██║██║██║╚██╗██║   ██║       ██╔═══╝ ██╔══██║╚════██║╚════██║██╔═══╝ ██║   ██║██╔══██╗   ██║
// ██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██║  ██║██████╔╝    ██████╔╝███████╗╚████╔╝ ██████╔╝    ██║ ╚═╝ ██║██║██║ ╚████║   ██║       ██║     ██║  ██║███████║███████║██║     ╚██████╔╝██║  ██║   ██║
// ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝     ╚═════╝ ╚══════╝ ╚═══╝  ╚═════╝     ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝       ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝
// Author @tiempor3al
// A big thank you to all the people that made this project possible:
// Marisol Hernández
// Deisy Ignacio
// Eduardo Zarate
// Ximena Pérez
// Mario Ramos
// Joel Romero
// Ken Sánchez
// Mariana Tamayo
// Marte Baquerizo
// James Richardson
// Jordan Rothstein
// Ali Ossayran
// Katie Brooks
// Mason Mullins
// @isabellegorilla
// @heromachine_eth
// @the_water_way
// @metamanjro
// @joso8181
// @Beanstamatic
// @volecule
// @thebmsbrand
// @letsbefriends
// @punkactual
// @jdt_lol
// @calvinhoenes
// and many more....
// Special thanks to @bitcoinski for all the help and tips
//
// The NomadBLVD mint pass is non-refundable and will be redeemed for the Nomad BLVD NFT Art

contract NomadPass is
    ERC1155,
    AccessControl,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply,
    EIP712
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _passCounter;

    struct Pass {
        uint256 maxItems;
        uint256 maxPerWallet;
        uint256 maxPerTransaction;
        uint256 price;
        uint256 open;
        uint256 close;
        address redeemContract;
    }

    mapping(uint256 => Pass) private _passes;
    mapping(bytes32 => address) private _redeemedPasses;
    string private _contractURI;

    //Events
    event DatesChanged(uint256[] ids, uint256[] open, uint256[] close);

    event RedeemedPass(bytes32 hash, address account);

    event MaxPerWalletChanged(uint256[] ids, uint256[] maxPerWallet);

    event MaxPerTransactionChanged(uint256[] ids, uint256[] maxPerTransaction);

    event PricesChanged(uint256[] ids, uint256[] prices);

    event MaxItemsChanged(uint256[] ids, uint256[] maxItems);

    event RedeemContractAddressChanged(
        uint256[] ids,
        address[] redeemContracts
    );

    event UriChanged(string newUri);

    /// @dev We setup the roles and the name for the Smart Contract
    constructor(string memory newContractName)
        ERC1155("")
        EIP712(newContractName, "1.0.0")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(WITHDRAWER_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, msg.sender);
    }

    /// @dev Setup method
    /// @param numPasses The number of passes to setup
    /// @param maxItems An array containing the maximum of passes,
    // for example if we defined numPasses = 2, and we want 2500 and 5000 maxItems, this array should be [2500, 5000]

    /// @param maxPerWallet An array containing the maximum allowed passes per wallet
    /// @param maxPerTransaction An array containing the maximum allowed passes per transaction

    /// @param prices An array containing the prices for the passes
    /// @param open An array containing timestamp values indicating when the sale is open for each pass
    /// @param close An array containing timestamp values indicating when the sale is closed for each pass.
    function setup(
        uint256 numPasses,
        uint256[] memory maxItems,
        uint256[] memory maxPerWallet,
        uint256[] memory maxPerTransaction,
        uint256[] memory prices,
        uint256[] memory open,
        uint256[] memory close
    ) external onlyRole(OPERATOR_ROLE) {
        require(numPasses > 0, "INVALID_NUMBER_TOKENS");
        require(maxItems.length == numPasses, "INVALID_MAX_ITEMS_SIZE");

        require(maxPerWallet.length == numPasses, "INVALID_MAX_WALLET_SIZE");
        require(
            maxPerTransaction.length == numPasses,
            "INVALID_MAX_TRANSACTION_SIZE"
        );

        require(prices.length == numPasses, "INVALID_PRICES_SIZE");

        require(open.length == numPasses, "INVALID_OPEN_SIZE");
        require(close.length == numPasses, "INVALID_CLOSE_SIZE");

        for (uint256 i = 0; i < numPasses; i++) {
            require(maxItems[i] > 0, "INVALID_MAX_ITEM");
            require(open[i] <= close[i], "INVALID_DATES");

            Pass storage pass = _passes[_passCounter.current()];
            pass.maxItems = maxItems[i];

            pass.maxPerTransaction = maxPerTransaction[i];
            pass.maxPerWallet = maxPerWallet[i];
            pass.price = prices[i];
            pass.open = open[i];
            pass.close = close[i];

            _passCounter.increment();
        }
    }

    ///@dev Remove a hash from the redeemedPasses mapping. Should be used only if something goes wrong
    function deleteHash(bytes32 hash) external onlyRole(OPERATOR_ROLE) {
        delete _redeemedPasses[hash];
    }

    ///@dev Sets the contract URI for OpenSea
    ///@param newContractURI The new URI for the contract
    function setContractURI(string memory newContractURI)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _contractURI = newContractURI;
    }

    ///Returns the contract URI for OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    ///Returns the current pass counter
    function getCounter() external view returns (uint256) {
        return _passCounter.current();
    }

    //Returns the price for passId
    function getPrice(uint256 passId) public view returns (uint256) {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.price;
    }

    //Returns the maxItems for passId
    function getMaxItems(uint256 passId) public view returns (uint256) {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.maxItems;
    }

    //Returns the open date for passId
    function getOpen(uint256 passId) public view returns (uint256) {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.open;
    }

    //Returns the close date for passId
    function getClose(uint256 passId) public view returns (uint256) {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.close;
    }

    //Returns the maxPerWallet for passId
    function getMaxPerWallet(uint256 passId) public view returns (uint256) {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.maxPerWallet;
    }

    //Returns the maxPerTransaction for passId
    function getMaxPerTransaction(uint256 passId)
        public
        view
        returns (uint256)
    {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.maxPerTransaction;
    }

    //Returns the redeemContract for passId
    function getRedeemContract(uint256 passId) public view returns (address) {
        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        return pass.redeemContract;
    }

    //Returns the redeemContract for passId
    function resetPass(uint256 passId) external onlyRole(OPERATOR_ROLE) {
        delete (_passes[passId]);
    }

    ///@dev Resets the internal counter to newIndex
    function resetCounter(uint256 newIndex) external onlyRole(OPERATOR_ROLE) {
        _passCounter.reset();
        for (uint256 i = 0; i < newIndex; i++) {
            _passCounter.increment();
        }
    }

    /// @dev Pause the contract if anything weird happens
    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /// @dev Unpause the contarct
    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /// @dev After doing the setup, this method can be used to modify the sale dates.
    /// This dates are used in the mintPass method
    /// @param ids The ids of the passes
    /// @param open An array containing timestamp values indicating when the sale is open for each pass
    /// @param close An array containing timestamp values indicating when the sale is closed for each pass
    function setDates(
        uint256[] memory ids,
        uint256[] memory open,
        uint256[] memory close
    ) external onlyRole(OPERATOR_ROLE) {
        require(ids.length > 0, "INVALID_TOKENS_SIZE");
        require(open.length == ids.length, "INVALID_OPEN_SIZE");
        require(close.length == ids.length, "INVALID_CLOSE_SIZE");

        for (uint256 i = 0; i < ids.length; i++) {
            require(open[i] <= close[i], "INVALID_DATES");
            Pass storage pass = _passes[ids[i]];

            require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
            pass.open = open[i];
            pass.close = close[i];
        }

        emit DatesChanged(ids, open, close);
    }

    /// @dev After doing the setup, this method can be used to modify the maximum passes per wallet
    /// @param ids The ids of the passes
    /// @param maxPerWallet An array containing the maximum allowed passes per wallet.
    function setMaxPerWallet(
        uint256[] memory ids,
        uint256[] memory maxPerWallet
    ) external onlyRole(OPERATOR_ROLE) {
        require(ids.length > 0, "INVALID_TOKENS_SIZE");
        require(maxPerWallet.length == ids.length, "INVALID_MAX_WALLET_SIZE");

        for (uint256 i = 0; i < ids.length; i++) {
            Pass storage pass = _passes[ids[i]];
            require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
            pass.maxPerWallet = maxPerWallet[i];
        }
        emit MaxPerWalletChanged(ids, maxPerWallet);
    }

    /// @dev After doing the setup, this method can be used to modify the maximum passes per transaction
    /// @param ids The ids of the passes
    /// @param maxPerTransaction An array containing the maximum allowed passes per transaction.
    function setMaxPerTransaction(
        uint256[] memory ids,
        uint256[] memory maxPerTransaction
    ) external onlyRole(OPERATOR_ROLE) {
        require(ids.length > 0, "INVALID_TOKENS_SIZE");
        require(
            maxPerTransaction.length == ids.length,
            "INVALID_MAX_TRANSACTION_SIZE"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            Pass storage pass = _passes[ids[i]];
            require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
            pass.maxPerTransaction = maxPerTransaction[i];
        }
        emit MaxPerTransactionChanged(ids, maxPerTransaction);
    }

    /// @dev After doing the setup, this method can be used to modify the redeem contract address for each pass.
    /// @param ids The ids of the passes
    /// @param redeemContracts The addresses for each redeem contract
    function setRedeemContracts(
        uint256[] memory ids,
        address[] memory redeemContracts
    ) external onlyRole(OPERATOR_ROLE) {
        require(ids.length > 0, "INVALID_TOKENS_SIZE");
        require(
            redeemContracts.length == ids.length,
            "INVALID_REDEEM_CONTRACTS_SIZE"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            Pass storage pass = _passes[ids[i]];
            require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
            pass.redeemContract = redeemContracts[i];
        }
        emit RedeemContractAddressChanged(ids, redeemContracts);
    }

    /// @dev After doing the setup, this method can be used to modify the redeem price of each pass.
    /// The prices are used in the redeemPass method
    /// @param ids The ids of the passes
    /// @param prices The prices of the passes
    function setPrices(uint256[] memory ids, uint256[] memory prices)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(ids.length > 0, "INVALID_TOKENS_SIZE");
        require(prices.length == ids.length, "INVALID_PRICES_SIZE");

        for (uint256 i = 0; i < ids.length; i++) {
            Pass storage pass = _passes[ids[i]];
            require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
            pass.price = prices[i];
        }
        emit PricesChanged(ids, prices);
    }

    /// @dev After doing the setup, this method can be used to modify the maximum items for a pass
    /// @param ids The ids of the passes
    /// @param maxItems The maximum number of items
    function setMaxItems(uint256[] memory ids, uint256[] memory maxItems)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(ids.length > 0, "INVALID_TOKENS_SIZE");
        require(maxItems.length == ids.length, "INVALID_MAX_ITEMS_SIZE");

        for (uint256 i = 0; i < ids.length; i++) {
            require(maxItems[i] > 0, "INVALID_MAX_ITEM");
            Pass storage pass = _passes[ids[i]];
            require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
            pass.maxItems = maxItems[i];
        }
        emit MaxItemsChanged(ids, maxItems);
    }

    /// @dev This method can be used to modify the uri for the passes
    /// @param newUri The uri to be used, it should contain the {id} string.
    /// See:  https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions
    function setURI(string memory newUri) external onlyRole(OPERATOR_ROLE) {
        _setURI(newUri);
        emit UriChanged(newUri);
    }

    /// @dev This method can be used to mint a pass using a signature.
    /// The main advantage of a signature over a Merkle Tree is that
    // there is no need to update the root if the whitelist changes.
    /// @param passId The id of the pass
    /// @param amount The amount of passes to mint
    /// @param nonce A value that should be unique per parameter combination. It helps the prevention of double minting
    /// @param signature The signature for the operation, it is generated off-chain.
    /// See: https://github.com/OpenZeppelin/workshops/tree/master/06-nft-merkle-drop
    function mintPass(
        uint256 passId,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external payable {
        require(!paused(), "CONTRACT_PAUSED");

        Pass storage pass = _passes[passId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");

        bytes32 hash = _hash(msg.sender, passId, amount, nonce);

        require(_verify(hash, signature), "INVALID_SIGNATURE");
        require(_redeemedPasses[hash] == address(0), "TOKEN_ALREADY_REDEEMED");

        require(block.timestamp >= pass.open, "INVALID_OPEN_DATE");
        require(block.timestamp <= pass.close, "INVALID_CLOSE_DATE");

        if (pass.maxPerTransaction > 0) {
            require(
                amount <= pass.maxPerTransaction,
                "INVALID_MAX_PER_TRANSACTION"
            );
        }

        if (pass.maxPerWallet > 0) {
            uint256 balance = balanceOf(msg.sender, passId);
            require(
                (balance + amount) <= pass.maxPerWallet,
                "INVALID_MAX_PER_WALLET"
            );
        }

        if (pass.price > 0) {
            require(msg.value >= (pass.price * amount), "VALUE_BELOW_PRICE");
        }

        require(
            (totalSupply(passId) + amount) <= pass.maxItems,
            "PURCHASE_EXCEED_MAX_ITEMS"
        );

        _mint(msg.sender, passId, amount, "");
        _redeemedPasses[hash] = msg.sender;
        emit RedeemedPass(hash, msg.sender);
    }

    function burnFromRedeemedToken(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        require(!paused(), "CONTRACT_PAUSED");
        Pass storage pass = _passes[id];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        require(pass.redeemContract != address(0), "INVALID_CONTRACT_ADDRESS");
        require(msg.sender == pass.redeemContract, "INVALID_SENDER_ADDRESS");

        _burn(account, id, amount);
    }

    function mint(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external onlyRole(OPERATOR_ROLE) {
        require(!paused(), "CONTRACT_PAUSED");
        Pass storage pass = _passes[tokenId];
        require(pass.maxItems > 0, "TOKEN_ID_NOT_EXIST");
        require(
            (totalSupply(tokenId) + amount) <= pass.maxItems,
            "PURCHASE_EXCEED_MAX_ITEMS"
        );
        _mint(account, tokenId, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyRole(OPERATOR_ROLE) {
        require(!paused(), "CONTRACT_PAUSED");
        _mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw(uint256 amount, address payable to)
        external
        onlyRole(WITHDRAWER_ROLE)
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "BALANCE_ZERO");
        require(balance >= amount, "AMOUNT_GT_BALANCE");

        // solhint-disable-next-line
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "WITHDRAW_FAILED");
    }

    function _hash(
        address account,
        uint256 tokenId,
        uint256 amount,
        uint256 nonce
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFT(address account,uint256 tokenId,uint256 amount,uint256 nonce)"
                        ),
                        account,
                        tokenId,
                        amount,
                        nonce
                    )
                )
            );
    }

    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return hasRole(SIGNER_ROLE, ECDSA.recover(digest, signature));
    }
}