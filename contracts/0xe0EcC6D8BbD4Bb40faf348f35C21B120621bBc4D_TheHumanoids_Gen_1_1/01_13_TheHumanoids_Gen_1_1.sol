// SPDX-License-Identifier: MIT

/*
                    ████████╗██╗  ██╗███████╗
                    ╚══██╔══╝██║  ██║██╔════╝
                       ██║   ███████║█████╗
                       ██║   ██╔══██║██╔══╝
                       ██║   ██║  ██║███████╗
                       ╚═╝   ╚═╝  ╚═╝╚══════╝
██╗  ██╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗ ██████╗ ██╗██████╗ ███████╗
██║  ██║██║   ██║████╗ ████║██╔══██╗████╗  ██║██╔═══██╗██║██╔══██╗██╔════╝
███████║██║   ██║██╔████╔██║███████║██╔██╗ ██║██║   ██║██║██║  ██║███████╗
██╔══██║██║   ██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██║██║  ██║╚════██║
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝██║██████╔╝███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝


The Humanoids Gen 1.1 Contract

*/

pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721NOIDS.sol";

contract TheHumanoids_Gen_1_1 is ERC721NOIDS, Ownable {
    string public baseURI;

    mapping(address => bool) private _allowedMinters;
    address private _signerAddress;

    constructor() ERC721NOIDS("The Humanoids Gen 1.1", "HMNDS11") {
    }

    function addMinter(address account) external onlyOwner {
        _allowedMinters[account] = true;
    }

    function removeMinter(address account) external onlyOwner {
        _allowedMinters[account] = false;
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function claim(uint256 amount, uint256 amountMax, uint256 deadlineTimestamp, bytes32 signatureR, bytes32 signatureVS) external {
        require(amount > 0, "No amount specified");
        require(deadlineTimestamp > block.timestamp, "Deadline to claim has passed");

        bytes32 hash = keccak256(abi.encode(msg.sender, amountMax, deadlineTimestamp));
        address signerAddress = ECDSA.recover(hash,  signatureR,  signatureVS);
        require(_signerAddress == signerAddress, "Invalid signature");

        _mint(msg.sender, amount, amountMax, deadlineTimestamp);
    }

    function mint(address to, uint256 amount, uint256 amountMax, uint256 deadlineTimestamp) external {
        require(_allowedMinters[msg.sender], "Not allowed to mint");

        _mint(to, amount, amountMax, deadlineTimestamp);
    }

    function mintStatusOf(address account) external view returns (OwnerData memory) {
        return _ownerData[account];
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function maxTokens() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function tokenIdOffset() external pure returns (uint256) {
        return TOKEN_ID_FIRST;
    }
}