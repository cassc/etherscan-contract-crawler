// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "../interfaces/IERC5484.sol";

contract InternalDao is ERC721, Ownable2Step, IERC5484 {
    /// @dev init first tokenId
    uint256 public nextTokenId = 1;

    string internal tokensURI;

    /// @dev Default Burn authentication
    BurnAuth public constant DEFAULT_BURN_AUTH = BurnAuth.IssuerOnly;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            CONSTRUCTOR
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    constructor(string memory _tokensURI) ERC721("Convergence Internal DAO", "cvgPDAO") {
        tokensURI = _tokensURI;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /**
     * @notice Mint a community SBT only for whitelisted users
     * @param _receiver address of the new DAO member
     */
    function mint(address _receiver) external onlyOwner {
        require(balanceOf(_receiver) == 0, "ALREADY_MEMBER");

        /// @dev mint tokenId to the specified receiver
        _mint(_receiver, nextTokenId);

        emit Issued(address(0), _receiver, nextTokenId++, DEFAULT_BURN_AUTH);
    }

    /**
     * @notice Mint several community SBTs only for whitelisted users
     * @param _receivers addresses of the new DAO members
     */
    function mintMultiple(address[] calldata _receivers) external onlyOwner {
        uint256 _nextId = nextTokenId;
        for (uint256 i; i < _receivers.length; ) {
            address _receiver = _receivers[i];
            require(balanceOf(_receiver) == 0, "ALREADY_MEMBER");

            /// @dev mint tokenId to the specified receiver
            _mint(_receiver, _nextId);

            emit Issued(address(0), _receiver, _nextId++, DEFAULT_BURN_AUTH);
            unchecked {
                ++i;
            }
        }
        nextTokenId = _nextId;
    }

    /**
     * @notice Definitively burn an owned SBT
     * @param _tokenId to burn
     */
    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
    }

    /// @notice Set tokens URI
    function setTokensURI(string memory _tokensURI) external onlyOwner {
        tokensURI = _tokensURI;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            GETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @notice method to get token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return tokensURI;
    }

    /// @notice method to get the burn authentication for a tokenId
    function burnAuth(uint256 tokenId) external view override returns (BurnAuth) {
        _requireMinted(tokenId);
        return DEFAULT_BURN_AUTH;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @notice Overrided transfer that systematically reverts
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        revert("ERC5484: NON_TRANSFERABLE");
    }
}