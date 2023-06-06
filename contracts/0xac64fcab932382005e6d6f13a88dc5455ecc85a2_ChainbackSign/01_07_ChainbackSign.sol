// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ChainbackSign is Ownable {
    /**
     * @notice String indexed parameters are hashed, search by hash, e.g. web3.utils.keccak256("your_string_here").
     */
    event Enable(
        address indexed sender,
        string indexed indexedChainbackHash,
        string indexed indexedCid
    );
    /**
     * @notice String indexed parameters are hashed, search by hash, e.g. web3.utils.keccak256("your_string_here").
     */
    event Sign(
        address indexed sender,
        string indexed indexedChainbackHash,
        string indexed indexedCid
    );
    event Withdraw(
        address indexed sender,
        address indexed devWallet,
        uint256 amount
    );

    IERC20 private immutable _token;

    address private _serverAdminAddress;
    address private _devWallet;

    uint256 private _enableFee;
    uint256 private _enableFreeLimit;
    uint256 private _signFee;
    uint256 private _signFreeLimit;

    mapping(bytes => bool) private _usedSignatures;

    /**
     * @param tokenAddress - token address
     * @param serverAdminAddress - address to verify that signed by server
     * @param devWallet - target address to withdraw tokens from contract
     * @param enableFee - fee for 'enable'
     * @param enableFreeLimit - token min balance for free (without fee) 'enable'
     * @param signFee - fee for 'sign'
     * @param signFreeLimit - token min balance for free (without fee) 'sign'
     */
    constructor(
        address tokenAddress,
        address serverAdminAddress,
        address devWallet,
        uint256 enableFee,
        uint256 enableFreeLimit,
        uint256 signFee,
        uint256 signFreeLimit
    ) {
        _token = IERC20(tokenAddress);
        _serverAdminAddress = serverAdminAddress;
        _devWallet = devWallet;
        _enableFee = enableFee;
        _enableFreeLimit = enableFreeLimit;
        _signFee = signFee;
        _signFreeLimit = signFreeLimit;
    }

    /**
     * @notice Returns the 'enable' fee.
     */
    function getEnableFee() external view returns (uint256) {
        return _enableFee;
    }

    /**
     * @notice Returns token min balance for free (without fee) 'enable'.
     */
    function getEnableFreeLimit() external view returns (uint256) {
        return _enableFreeLimit;
    }

    /**
     * @notice Returns the 'sign' fee.
     */
    function getSignFee() external view returns (uint256) {
        return _signFee;
    }

    /**
     * @notice Returns token min balance for free (without fee) 'sign'.
     */
    function getSignFreeLimit() external view returns (uint256) {
        return _signFreeLimit;
    }

    /**
     * @notice Returns address to verify that signed by server.
     */
    function getServerAdminAddress() external view returns (address) {
        return _serverAdminAddress;
    }

    /**
     * @notice Returns target address to withdraw tokens from contract. 
     */
    function getDevWallet() external view returns (address) {
        return _devWallet;
    }

    /**
     * @notice Updates fees anf limits. Allowed only for contract owner.
     * @param newEnableFee - fee for 'enable'
     * @param newEnableFreeLimit - token min balance for free (without fee) 'enable'
     * @param newSignFee - fee for 'sign'
     * @param newSignFreeLimit - token min balance for free (without fee) 'sign'
     */
    function updateFeesAndLimits(
        uint256 newEnableFee,
        uint256 newEnableFreeLimit,
        uint256 newSignFee,
        uint256 newSignFreeLimit
    ) external onlyOwner {
        _enableFee = newEnableFee;
        _enableFreeLimit = newEnableFreeLimit;
        _signFee = newSignFee;
        _signFreeLimit = newSignFreeLimit;
    }

    /**
     * @notice Updates address to verify that signed by server. Allowed only for contract owner.
     * @param newServerAdminAddress - address to verify that signed by server
     */
    function updateServerAdminAddress(address newServerAdminAddress) external onlyOwner {
        _serverAdminAddress = newServerAdminAddress;
    }

    /**
     * @notice Updates target address to withdraw tokens from contract. Allowed only for contract owner.
     * @param newDevWallet - target address to withdraw tokens from contract
     */
    function updateDevWallet(address newDevWallet) external onlyOwner {
        _devWallet = newDevWallet;
    }

    /**
     * @notice Verifies that data is signed by server, transfers fee depending on defined 'enable' fees and limits.
     * @param chainbackHash - Chainback identifier
     * @param cid - IPFS identifier
     * @param description - description entered by user
     * @param salt - random unique number
     * @param signature - signature created by server
     */
    function enableChainbackSign(
        string calldata chainbackHash,
        string calldata cid,
        string calldata description,
        uint256 salt,
        bytes calldata signature
    ) external {
        require(!_usedSignatures[signature], "CB: Signature is used");
        _usedSignatures[signature] = true;

        uint256 balance = _token.balanceOf(_msgSender());
        uint256 fee = balance >= _enableFreeLimit ? 0 : _enableFee;
        if (fee > 0) {
            require(_token.balanceOf(_msgSender()) >= fee, "CB: Not enough tokens");
            require(_token.allowance(_msgSender(), address(this)) >= fee, "CB: Not enough tokens approved");
        }

        bytes32 messageHash = getEnableMessageHash(_msgSender(), chainbackHash, cid, description, salt);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        require(
            ECDSA.recover(ethSignedMessageHash, signature) == _serverAdminAddress,
            "CB: Invalid signature"
        );

        if (fee > 0) {
            bool transferSuccess = _token.transferFrom(
                _msgSender(),
                address(this),
                fee
            );
            require(transferSuccess, "CB: Fee transfer failed");
        }

        emit Enable(_msgSender(), chainbackHash, cid);
    }

    /**
     * @notice Verifies that data is signed by server, transfers fee depending on defined 'sign' fees and limits.
     * @param chainbackHash - Chainback identifier
     * @param cid - IPFS identifier
     * @param name - name entered by user
     * @param comment - comment entered by user
     * @param salt - random unique number
     * @param signature - signature created by server
     */
    function sign(
        string calldata chainbackHash,
        string calldata cid,
        string calldata name,
        string calldata comment,
        uint256 salt,
        bytes calldata signature
    ) external {
        require(!_usedSignatures[signature], "CB: Signature is used");
        _usedSignatures[signature] = true;

        uint256 balance = _token.balanceOf(_msgSender());
        uint256 fee = balance >= _signFreeLimit ? 0 : _signFee;
        if (fee > 0) {
            require(_token.balanceOf(_msgSender()) >= fee, "CB: Not enough tokens");
            require(_token.allowance(_msgSender(), address(this)) >= fee, "CB: Not enough tokens approved");
        }

        bytes32 messageHash = getSignMessageHash(_msgSender(), chainbackHash, cid, name, comment, salt);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        require(
            ECDSA.recover(ethSignedMessageHash, signature) == _serverAdminAddress,
            "CB: Invalid signature"
        );

        if (fee > 0) {
            bool transferSuccess = _token.transferFrom(
                _msgSender(),
                address(this),
                fee
            );
            require(transferSuccess, "CB: Fee tansfer failed");
        }

        emit Sign(_msgSender(), chainbackHash, cid);
    }

    /**
     * @notice Withdraws all tokens to defined target address. Allowed only for contract owner.
     */
    function withdraw() external onlyOwner {
        address wallet = _devWallet;

        uint256 balance =_token.balanceOf(address(this));
        require(balance > 0, "CB: No tokens to withdraw");

        bool transferSuccess = _token.transfer(
            wallet,
            balance
        );
        require(transferSuccess, "CB: Transfer failed");
        emit Withdraw(_msgSender(), wallet, balance);
    }

    /**
     * @notice Message hash for 'enable', could also be generated off-chain, e.g. with web3j.
     */
    function getEnableMessageHash(
        address sender,
        string calldata chainbackHash,
        string calldata cid,
        string calldata description,
        uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(sender, chainbackHash, cid, description, salt));
    }

    /**
     * @notice Message hash for 'sign', could also be generated off-chain, e.g. with web3j.
     */
    function getSignMessageHash(
        address sender,
        string calldata chainbackHash,
        string calldata cid,
        string calldata name,
        string calldata comment,
        uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(sender, chainbackHash, cid, name, comment, salt));
    }
}