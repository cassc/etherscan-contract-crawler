// SPDX-License-Identifier: MIT

// @author DNX

/**⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢘⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣵⣿⡿⡹⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⣾⠵⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣈⢤⡵⠒⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⡈⡚⠶⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣀⣞⠶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣀⣯⣿⢌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣈⣬⣮⣾⣿⣿⣯⣮⣎⢄⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠐⣿⣿⣿⣯⢌⠀⠀⠀⠀⠀⠀⣈⣚⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣞⡊⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⡰⣿⣿⣿⣿⣯⠌⠀⠀⠀⣨⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⡱⣿⣿⣿⣿⣟⣎⠈⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣳⣿⣿⣿⣿⣯⠏⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠁⠐⣿⣿⣿⣿⣿⣿⠈⣱⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠄⡰⣿⣿⣿⣿⣿⣏⠀⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⡈⠈⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣳⣿⣿⣿⣿⣿⢎⠐⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢀⣬⣿⣞⣎⠈⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣾⣿⣿⣿⣿⣞⣎⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡯⠈⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⠈⡀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⡱⣿⣿⣿⣿⣿⣿⣯⠈⠀
⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⠀⣳⣿⣿⣿⣿⣿⣿⣏⠀

                     FRESH FOOLS

 */

pragma solidity 0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FreshFools is ERC721A, Ownable, ReentrancyGuard {
    address private immutable _defender;
    using Address for address;

    // Variables
    string private _baseTokenURI;
    uint256 public mintPrice = 0.04 ether;
    uint256 public collectionSize = 10000;
    uint256 public reservedSize = 50;
    uint256 public maxPerWallet = 20;
    uint256 public maxPerTx = 10;
    bool public publicMintPaused = true;

    // Constructor
    constructor(address defender) ERC721A("Fresh Fools", "TFF") {
        require(defender != address(0));
        _defender = defender;
    }

    // Modifier
    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender() {
        _onlySender();
        _;
    }

    // Functions

    /**
     * @dev Mints a new token for the given address.
     * @param to The address to which the token is minted.
     * @param amount The amount of tokens minted.
     */
    function mintByOwner(address to, uint256 amount) external onlySender onlyOwner {
        require(amount <= reservedSize, "Minting amount exceeds reserved size");
        require((totalSupply() + amount) <= collectionSize, "Sold out!");
        _safeMint(to, amount);
    }


    /**
        * @dev Public mints a new token 
        * @param hash The hash of the token
        * @param signature The signature of the token
     */
    function mint(bytes32 hash, bytes memory signature) external payable onlySender nonReentrant {
        require(!publicMintPaused, "Mint is paused");

        require(
            hash ==
                keccak256(
                    abi.encode(msg.sender, balanceOf(msg.sender), address(this))
                ),
            "Invalid hash"
        );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) ==
                _defender,
            "Invalid signature"
        );

        uint256 amount = _getMintAmount(msg.value);

        require(
            amount <= maxPerTx,
            "Minting amount exceeds max per transaction"
        );

        require(
            balanceOf(msg.sender) + amount <= maxPerWallet,
            "You can't mint more than max per wallet"
        );

        _safeMint(msg.sender, amount);
    }


    /**
     * @dev get the minting amount for the given value
     * @param value The value of the transaction
     */
    function _getMintAmount(uint256 value) internal view returns (uint256) {
        uint256 remainder = value % mintPrice;
        require(remainder == 0, "Send a divisible amount of eth");

        uint256 amount = value / mintPrice;
        require(amount > 0, "Amount to mint is 0");
        require(
            (totalSupply() + amount) <= collectionSize - reservedSize,
            "Sold out!"
        );
        return amount;
    }

    // Internal functions

    function setReservedSize(uint256 _reservedSize) external onlyOwner {
        reservedSize = _reservedSize;
    }

    function setPaused() external onlyOwner {
        publicMintPaused = !publicMintPaused;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAll() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool dm, ) = payable(0xb18D6eE98085f713af61A13187c277C166397398).call{
            value: (balance * 19) / 100
        }("");
        require(dm, "Withdraw failed");
        (bool jp, ) = payable(0x925AAD658B009B8A5ac3dB1eCFD9B7e6142780C0).call{
            value: (balance * 19) / 100
        }("");
        require(jp, "Withdraw failed");
        (bool j, ) = payable(0x303095f338B59B9bd275064bdAc974206F01BE9d).call{
            value: (balance * 19) / 100
        }("");
        require(j, "Withdraw failed");
        (bool z, ) = payable(0x4af26427aDB27ed0ab0f6DdB6CB890786e01E044).call{
            value: (balance * 19) / 100
        }("");
        require(z, "Withdraw failed");
        (bool d, ) = payable(0x54c326411c4D9BE46bDa68f8227872Dd2d6ce1E2).call{
            value: (balance * 19) / 100
        }("");
        require(d, "Withdraw failed");
        (bool cm, ) = payable(0xD35E48e47bCe08fc733D48a8E34496eEE4B9e93a).call{
            value: (balance * 5) / 100
        }("");
        require(cm, "Withdraw failed");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }
}