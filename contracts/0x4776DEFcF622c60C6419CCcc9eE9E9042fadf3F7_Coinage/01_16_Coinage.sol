// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @dev Using strings in revert - despite the higher gas its the the best way to extract the error message on the the frontend.
 */

error WithdrawFailed();

contract Coinage is Ownable, ERC1155Supply, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    struct TokenType {
        uint256 id;
        uint256 price;
        uint256 supply;
    }

    event networkMintSuccess(
        uint256 coinageUserId,
        address minterWalletAddress,
        uint256 networkGroupId
    );
    event caucusMintSuccess(address minter);
    event subscriberMintSuccess(address minter);

    address private signerAddress = 0x569E2DFfDCd7F5F78742E7BF5bCdBF23e0d0Fb7f;
    address private withdrawalAddress;
    string private baseURI;
    uint256 public maxNetworkGroupCount = 500;
    address private burnContract;

    mapping(uint256 => uint256) public _networkGroups;
    mapping(string => bool) public _saleActive;
    mapping(string => bool) private _usedReferralCodes;

    /**
     * @dev
     * Need to update the caucus price using `updateToken` - 999 is placeholder
     */
    TokenType Network = TokenType(1, 1 ether, 1000);
    TokenType Caucus = TokenType(2, 999 ether, 9000);
    TokenType Subscriber = TokenType(3, 0 ether, 1);

    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseUri, address _withdrawlAddress)
        ERC1155(_baseUri)
    {
        withdrawalAddress = _withdrawlAddress;
        baseURI = _baseUri;
        _saleActive["network"] = true;
        _saleActive["caucus"] = false;
        _saleActive["subscriber"] = false;
    }

    /**
     * @dev Match Signer
     * Used to make sure the transaction was signed by our admin wallet
     */

    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return signedHash.recover(signature) == signerAddress;
    }

    /**
     * @dev Update Price / Supply
     * Unsure of what caucus price will be when launches so setting the ability to update it
     */

    function updateToken(
        uint256 id,
        uint256 price,
        uint256 supply
    ) external onlyOwner {
        if (id == Network.id) {
            Network.price = price;
            Network.supply = supply;
        }
        if (id == Caucus.id) {
            Caucus.price = price;
            Caucus.supply = supply;
        }
    }

    /**
     * @dev Owner Mint
     * Mint Free Tokens to an address
     */

    function ownerMint(
        address to,
        uint256 amount,
        uint256 id
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }

    /**
     * @dev Network Mint
     * Mint Token ID 1 for network mint
     */
    function networkMint(
        bytes32 hash,
        bytes memory signature,
        string memory referralCode,
        uint256 networkGroupId,
        uint256 coinageUserId
    ) external payable {
        if (!_saleActive["network"]) revert("Network sale not active");
        if (totalSupply(Network.id) == Network.supply) revert("Sold Out");
        if (_networkGroups[networkGroupId] >= maxNetworkGroupCount)
            revert("Max Network Group Size");

        uint256 ownerTokenCount = balanceOf(msg.sender, Network.id);

        if (ownerTokenCount > 0) {
            revert("Already Purchased");
        }
        if (!matchAddresSigner(hash, signature)) {
            revert("Signature Error");
        }
        if (_usedReferralCodes[referralCode]) {
            revert("Referral Code Used");
        }
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                msg.sender,
                referralCode,
                Strings.toString(networkGroupId),
                Strings.toString(coinageUserId)
            )
        );
        if (hash != msgHash) {
            revert("Hash Error");
        }
        if (msg.value != Network.price) revert("Incorrect ETH Sent");
        _usedReferralCodes[referralCode] = true;
        _networkGroups[networkGroupId] += 1;
        _mint(msg.sender, Network.id, 1, "");
        emit networkMintSuccess(coinageUserId, msg.sender, networkGroupId);
    }

    /**
     * @dev Caucus Mint
     * Mint Token ID 2 for caucus mint
     */
    function caucusMint(bytes32 hash, bytes memory signature) external payable {
        if (!_saleActive["caucus"]) revert("Caucus sale not active");

        if (totalSupply(Caucus.id) == Caucus.supply) revert("Sold Out");
        uint256 ownerTokenCount = balanceOf(msg.sender, Caucus.id);

        if (ownerTokenCount > 0) {
            revert("Already Purchased");
        }
        if (!matchAddresSigner(hash, signature)) {
            revert("Signature Error");
        }

        bytes32 msgHash = keccak256(
            abi.encodePacked(msg.sender, "Minting Caucus")
        );
        if (hash != msgHash) {
            revert("Signature Error");
        }
        if (msg.value != Caucus.price) revert("Incorrect ETH Sent");
        _mint(msg.sender, Caucus.id, 1, "");
        emit caucusMintSuccess(msg.sender);
    }

    /**
     * @dev Subscriber Mint
     * Mint Token ID 3 for caucus mint (free)
     */
    function subscriberMint() external {
        if (!_saleActive["subscriber"]) revert("Subscriber sale not active");

        uint256 ownerTokenCount = balanceOf(msg.sender, Subscriber.id);

        if (ownerTokenCount > 0) {
            revert("Already Purchased");
        }

        _mint(msg.sender, Subscriber.id, 1, "");
        emit subscriberMintSuccess(msg.sender);
    }

    function setBurnContractAddress(address _burnAddress) external onlyOwner {
        burnContract = _burnAddress;
    }

    function burnTokens(
        address burnTokenAddress,
        uint256 qty,
        uint256 id
    ) external {
        if (qty > balanceOf(burnTokenAddress, id)) {
            revert("Trying to burn more than owned");
        }
        if (id == Subscriber.id) {
            revert("Can't burn subscriber tokens");
        }
        if (burnContract == address(0)) {
            revert("Burning not active");
        }
        if (msg.sender != burnContract) {
            revert("Invalid burn contract address");
        }
        _burn(burnTokenAddress, id, qty);
    }

    // Withdrawal Functions

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(withdrawalAddress).call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawTokens(IERC20 token) public onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // Get Functions
    function getNetworkCount(uint256 networkId) public view returns (uint256) {
        return _networkGroups[networkId];
    }

    // Set Functions

    function setWithdrawalAddress(address _withdrawalAddress)
        external
        onlyOwner
    {
        withdrawalAddress = _withdrawalAddress;
    }

    function setSignerWallet(address _signerWalletAddress) external onlyOwner {
        signerAddress = _signerWalletAddress;
    }

    function setMaxNetworkGroupCount(uint256 _newCount) external onlyOwner {
        maxNetworkGroupCount = _newCount;
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    function updateSaleActive(
        bool network,
        bool caucus,
        bool subscriber
    ) external onlyOwner {
        _saleActive["network"] = network;
        _saleActive["caucus"] = caucus;
        _saleActive["subscriber"] = subscriber;
    }

    // Retturns the uri for each token

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string.concat(baseURI, tokenId.toString());
    }
}