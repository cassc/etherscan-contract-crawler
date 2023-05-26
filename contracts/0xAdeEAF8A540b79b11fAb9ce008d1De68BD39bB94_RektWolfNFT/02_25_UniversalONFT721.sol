// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../ONFT721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC20Extented is IERC20 {
    function decimals() public view virtual returns (uint8);
}

/// @title Interface of the UniversalONFT standard
contract UniversalONFT721 is Ownable, ONFT721, ReentrancyGuard {
    uint256 public startMintId;
    uint256 public endMintId;

    string public baseURI;

    //userAddress => tokenId mapping
    mapping(address => uint256[]) public ledger;
    mapping(uint256 => bool) private isMinted;

    modifier isValidTokenIds(uint256[] memory _tokenIds) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _tokenIds[i] >= startMintId && _tokenIds[i] <= endMintId,
                "UniversalONFT721: tokenId does not belong to conditions"
            );
            require(
                isMinted[_tokenIds[i]] == false,
                "UniversalONFT721: already minted"
            );
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _layerZeroEndpoint,
        uint256 _startMintId,
        uint256 _endMintId
    ) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        startMintId = _startMintId;
        endMintId = _endMintId;

        setBaseURI(_baseURI);
    }

    function setLedger(address _owner, uint256[] memory _ledger)
        public
        onlyOwner
        isValidTokenIds(_ledger)
    {
        ledger[_owner] = _ledger;
    }

    function setLedgerOneTime(
        address[] memory _users,
        uint256[][] memory _tokenIds
    ) external onlyOwner {
        require(
            _users.length == _tokenIds.length,
            "users and tokens must be the same length"
        );
        for (uint256 i = 0; i < _users.length; i++) {
            setLedger(_users[i], _tokenIds[i]);
        }
    }

    function _mint(address _user) private {
        require(
            ledger[_user].length > 0,
            "UniversalONFT721: have no nfts to mint"
        );
        uint256[] memory mintArray = ledger[_user];
        for (uint256 i = 0; i < mintArray.length; i++) {
            uint256 newId = mintArray[i];
            _safeMint(msg.sender, newId);
        }
    }

    function publicMint() external {
        _mint(msg.sender);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "UniversalONFT721: Token does not exist!");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function isWhitelisted(address _user) external view returns (bool) {
        return ledger[_user].length > 0;
    }

    function getTokenListPerUser(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return ledger[_user];
    }
}