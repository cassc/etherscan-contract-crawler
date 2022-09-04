//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Collections is ERC721Upgradeable {
    using ECDSA for bytes32;

    /**
     * Upgradable contract
     *   Should not change the type of a variable
     *   Or change the order in which they are declared
     *   Or introduce a new variable before existing ones
     *   If you need to introduce a new variable, make sure you always do so at the end
     */

    uint256 private _tokenId;
    address private _verificationAddress;

    address public owner;

    // should not use tokenId#0 as value
    // because mapping will be initialized by 0
    mapping(string => uint256) private _combinationToTokenId;
    mapping(uint256 => string) private _tokenIdToURI;

    // introduce a new variable here

    event OwnerUpdated(address indexed user, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function initialize(
        address owner_,
        address verificationAddress_,
        string memory name_,
        string memory symbol_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        _verificationAddress = verificationAddress_;
        _tokenId++; // avoid 0 tokenId
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);
    }

    function create(
        string memory combinationHash,
        string memory ipfsAddress,
        bytes memory signature
    ) public {
        require(
            _combinationToTokenId[combinationHash] == 0,
            "token has been minted"
        );
        require(
            _verify(combinationHash, ipfsAddress, signature),
            "invalid signature"
        );
        _tokenIdToURI[_tokenId] = ipfsAddress;
        _combinationToTokenId[combinationHash] = _tokenId;
        _safeMint(msg.sender, _tokenId);
        _tokenId++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");
        return _tokenIdToURI[tokenId];
    }

    function getTokenId(string memory combinationHash)
        public
        view
        returns (uint256)
    {
        return _combinationToTokenId[combinationHash];
    }

    function totalSupply() public view returns (uint256) {
        // minus 1 because we do not have #0 token
        return _tokenId - 1;
    }

    function _verify(
        string memory combinationHash,
        string memory ipfsAddress,
        bytes memory signature
    ) internal view returns (bool) {
        bytes memory s = bytes(string.concat(combinationHash, ipfsAddress));
        // follow EIP-191
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(s.length),
                s
            )
        );
        return messageHash.recover(signature) == _verificationAddress;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * contract can receive eth, e.g. from creator fee
     */
    receive() external payable {}

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}