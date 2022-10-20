// SPDX-License-Identifier: MIT
/**
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                      +
+                                                                                                                      +
.                            __     __                              _     _____                                        .
.                            \ \   / /                   /\        | |   |  __ \                                       .
.                             \ \_/ /   _  __ _ _ __    /  \   _ __| |_  | |__) |_ _ ___ ___                           .
.                              \   / | | |/ _` | '_ \  / /\ \ | '__| __| |  ___/ _` / __/ __|                          .
.                               | || |_| | (_| | | | |/ ____ \| |  | |_  | |  | (_| \__ \__ \                          .
.                               |_| \__,_|\__,_|_| |_/_/    \_\_|   \__| |_|   \__,_|___/___/                          .                                                                                                  .
+                                                                                                                      +
+                                                                                                                      +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/
pragma solidity ^0.8.0;

import {GeneralERC721} from "../public/GeneralERC721.sol";
import {Payment} from "../public/Payment.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Yuan Pass NFT
 * @notice NFT minting:tokenid=auto inc, tokenURI=baseURI
 */
contract PassToken is GeneralERC721, Payment {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public OGPassToken;
    address public Galxe;
    address public BABT;
    bool public freeMintState = true;

    mapping(address => mapping(address => bool)) public freeMintStatus;

    modifier CheckFreeMint(address _tokenAddr) {
        require(freeMintState, "Free mint ended");
        require(_tokenAddr == Galxe || _tokenAddr == BABT, "Invalid address");
        require(!freeMintStatus[msg.sender][_tokenAddr], "Already Mint");
        _;
    }

    modifier OnlyBurnAddress() {
        require(msg.sender == OGPassToken, "Not burn address");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _recipient,
        uint256 _maxSupply,
        address _galxe,
        address _babt
    ) GeneralERC721(name, symbol, _recipient, _maxSupply) Payment(_recipient) {
        Galxe = _galxe;
        BABT = _babt;
    }

    function setBurnAddrss(address _OGPassToken) public onlyOwner {
        OGPassToken = _OGPassToken;
    }

    function setFreeMintState(bool _state) public onlyOwner {
        freeMintState = _state;
    }

    function inMint(uint256 _amount, address _account) private {
        for (uint256 i = 0; i < _amount; ++i) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(_account, id);
        }
    }

    /**
     * @notice mint Yuan Pass NFT
     * @param _price Pass mint price
     * @param _payToken payment token to mint
     * @param _amount amount of getting Pass token
     */
    function mint(
        uint256 _price,
        address _payToken,
        uint256 _amount,
        address _to
    )
        public
        payable
        whenNotPaused
        CheckPayment(_payToken)
        CheckSupply(_amount)
    {
        receivePayment(_price, _payToken, _amount);
        inMint(_amount, _to);
    }

    /**
     * @notice Free mint Yuan Pass NFT
     * @param _tokenAddr  BABT token address or
     */

    function freeMint(address _tokenAddr)
        public
        whenNotPaused
        CheckFreeMint(_tokenAddr)
        CheckSupply(1)
    {
        uint256 tokenBalance = IERC721(_tokenAddr).balanceOf(msg.sender);
        require(tokenBalance > 0, "No permission");
        freeMintStatus[msg.sender][_tokenAddr] = true;
        inMint(1, msg.sender);
    }

    function receivePayment(
        uint256 _price,
        address _payToken,
        uint256 _amount
    ) internal {
        require(prices[_payToken] == _price && _price > 0, "Invalid Price");
        if (_payToken == address(0)) {
            require(msg.value >= _price * _amount, "Invalid PayValue");
        } else {
            IERC20(_payToken).transferFrom(
                msg.sender,
                address(this),
                _price * _amount
            );
        }

        transToken(recipient, _price * _amount, _payToken);
    }

    /**
     * @notice Burning YUAN PASS NFT get OG PASS NFT
     * @param _userTokenId  burn tokenId
     */
    function burnToMint(uint256 _userTokenId)
        public
        whenNotPaused
        OnlyBurnAddress
    {
        require(
            ownerOf(_userTokenId) == tx.origin &&
                (getApproved(_userTokenId) == msg.sender ||
                    isApprovedForAll(tx.origin, msg.sender)),
            "The operator has permission"
        );
        _burn(_userTokenId);
    }
}