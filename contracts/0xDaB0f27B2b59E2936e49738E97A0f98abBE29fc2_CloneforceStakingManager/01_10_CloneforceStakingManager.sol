// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....
//                'dXMMWNO;                .......
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

contract CloneforceStakingManager is Ownable, IERC721Receiver, IERC1155Receiver {
    address private _admin;
    bool public contractPaused;

    // Struct for staked tokens
    struct StakedToken {
        address token; // address of token contract
        uint8 tokenType; // 1 = ERC-721, 2 = ERC-1155
        uint32 id; // token id
        uint8 amount; // amount of tokens staked
        uint256 timestamp; // timestamp of staking
    }

    // Holds all staked tokens by users
    mapping(address => StakedToken[]) public stakedTokensByUser;

    // Emitted when a user stakes a token
    event TokenStaked(
        address indexed user,
        address indexed token,
        uint32 indexed id,
        uint8 tokenType,
        uint8 amount,
        uint256 timestamp
    );

    // Emitted when a user unstakes a token
    event TokenUnstaked(
        address indexed user,
        address indexed token,
        uint32 indexed id,
        uint8 tokenType,
        uint8 amount,
        uint256 timestamp
    );

    // Holds whether a user can stake a specific token type
    mapping(address => bool) public isAllowedForStaking;
    mapping(address => bool) private _signatureRequiredToUnstake;
    address private _signatureKey;
    mapping(string => bool) private _usedNonces;

    constructor(address admin, address signatureKey) {
        _admin = admin;
        _signatureKey = signatureKey;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function setAllowedForStaking(
        address token,
        bool allowed,
        bool requireSigToUnstake
    ) external onlyOwnerOrAdmin {
        isAllowedForStaking[token] = allowed;
        _signatureRequiredToUnstake[token] = requireSigToUnstake;
    }

    function depositERC721Token(address token, uint32 id) private {
        // check if token is owned by user
        require(IERC721(token).ownerOf(id) == msg.sender, "Token not owned by user");

        // transfer token to contract
        IERC721(token).safeTransferFrom(msg.sender, address(this), id);
    }

    function depositERC1155Token(address token, uint32 id, uint8 amount) private {
        // check if token is owned by user
        require(
            IERC1155(token).balanceOf(msg.sender, id) >= amount,
            "Not enough tokens owned by user"
        );

        // transfer token to contract
        IERC1155(token).safeTransferFrom(msg.sender, address(this), id, amount, "");
    }

    function stakeToken(
        address token,
        uint8 tokenType,
        uint32 id,
        uint8 amount
    ) public callerIsUser {
        require(!contractPaused, "Contract paused");
        require(isAllowedForStaking[token], "Token not allowed for staking");
        require(tokenType == 1 || tokenType == 2, "Invalid token type");
        require(amount > 0, "Amount must be greater than 0");

        if (tokenType == 1) {
            require(amount == 1, "Amount must be 1 for ERC-721");
            depositERC721Token(token, id);
        } else {
            depositERC1155Token(token, id, amount);
        }

        // add token to user's staked tokens
        stakedTokensByUser[msg.sender].push(
            StakedToken(token, tokenType, id, amount, block.timestamp)
        );

        emit TokenStaked(msg.sender, token, id, tokenType, amount, block.timestamp);
    }

    function withdrawERC721Token(address token, uint32 id) private {
        // transfer token to user
        IERC721(token).safeTransferFrom(address(this), msg.sender, id);
    }

    function withdrawERC1155Token(address token, uint32 id, uint8 amount) private {
        // transfer token to user
        IERC1155(token).safeTransferFrom(address(this), msg.sender, id, amount, "");
    }

    function unstakeToken(
        address token,
        uint8 tokenType,
        uint32 id,
        uint8 amount,
        string calldata nonce,
        bytes memory signature
    ) public callerIsUser {
        require(!contractPaused, "Contract paused");
        require(tokenType == 1 || tokenType == 2, "Invalid token type");
        require(amount > 0, "Amount must be greater than 0");

        // if signature required, check signature
        if (_signatureRequiredToUnstake[token]) {
            require(!_usedNonces[nonce], "Nonce already used");

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }
            bytes32 _hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(token, tokenType, id, amount, nonce))
                )
            );
            require(ecrecover(_hash, v, r, s) == _signatureKey, "Invalid signature");

            _usedNonces[nonce] = true;
        }

        // get user's staked tokens
        StakedToken[] storage stakedTokens = stakedTokensByUser[msg.sender];

        // find token in user's staked tokens
        uint256 index = stakedTokens.length;
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (
                stakedTokens[i].token == token &&
                stakedTokens[i].tokenType == tokenType &&
                stakedTokens[i].id == id
            ) {
                index = i;
                break;
            }
        }

        // check if token was found
        require(index < stakedTokens.length, "Token not found");

        uint stakedAmount = stakedTokens[index].amount;
        require(stakedAmount >= amount, "Not enough tokens staked");

        if (tokenType == 1) {
            require(amount == 1, "Amount must be 1 for ERC-721");
            withdrawERC721Token(token, id);
        } else {
            withdrawERC1155Token(token, id, amount);
        }

        // remove `amount` of tokens from user's staked tokens
        if (stakedAmount > amount) {
            stakedTokens[index].amount -= amount;
        } else {
            stakedTokens[index] = stakedTokens[stakedTokens.length - 1];
            stakedTokens.pop();
        }

        emit TokenUnstaked(msg.sender, token, id, tokenType, amount, block.timestamp);
    }

    struct StakeUnstakeTokenParams {
        address token;
        uint8 tokenType;
        uint32 id;
        uint8 amount;
        string nonce;
        bytes signature;
    }

    struct BatchOperationParam {
        StakeUnstakeTokenParams params;
        bool stake;
    }

    function batchStakeUnstakeTokens(BatchOperationParam[] calldata params) external callerIsUser {
        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].stake) {
                stakeToken(
                    params[i].params.token,
                    params[i].params.tokenType,
                    params[i].params.id,
                    params[i].params.amount
                );
            } else {
                unstakeToken(
                    params[i].params.token,
                    params[i].params.tokenType,
                    params[i].params.id,
                    params[i].params.amount,
                    params[i].params.nonce,
                    params[i].params.signature
                );
            }
        }
    }

    function getStakedTokens(address user) external view returns (StakedToken[] memory) {
        return stakedTokensByUser[user];
    }

    function areNoncesUsed(string[] calldata nonces) external view returns (bool[] memory) {
        bool[] memory isUsed = new bool[](nonces.length);
        for (uint256 i = 0; i < nonces.length; i++) {
            isUsed[i] = _usedNonces[nonces[i]];
        }
        return isUsed;
    }

    function setSignatureKey(address signatureKey) external onlyOwner {
        _signatureKey = signatureKey;
    }

    // Emergency withdraw token from contract. Only owner or admin can call this function.
    // Will be used in case someone sends tokens to contract by mistake.
    function emergencyWithdrawToken(
        uint8 tokenType,
        address token,
        uint32 id,
        uint8 amount,
        address receiver
    ) external onlyOwnerOrAdmin {
        require(tokenType == 1 || tokenType == 2, "Invalid token type");

        // if token is staked, find it and unstake it
        bool staked = false;
        for (uint256 idx = 0; idx < stakedTokensByUser[receiver].length; idx++) {
            if (
                stakedTokensByUser[receiver][idx].token == token &&
                stakedTokensByUser[receiver][idx].tokenType == tokenType &&
                stakedTokensByUser[receiver][idx].id == id
            ) {
                uint stakedAmount = stakedTokensByUser[receiver][idx].amount;
                require(stakedAmount >= amount, "Not enough tokens staked");

                if (stakedAmount > amount) {
                    stakedTokensByUser[receiver][idx].amount -= amount;
                } else {
                    stakedTokensByUser[receiver][idx] = stakedTokensByUser[receiver][
                        stakedTokensByUser[receiver].length - 1
                    ];
                    stakedTokensByUser[receiver].pop();
                }
                staked = true;
                break;
            }
        }

        if (tokenType == 1) {
            require(amount == 1, "Amount must be 1 for ERC-721");
            IERC721(token).safeTransferFrom(address(this), receiver, id);
        } else {
            IERC1155(token).safeTransferFrom(address(this), receiver, id, amount, "");
        }

        if (staked) {
            emit TokenUnstaked(receiver, token, id, tokenType, amount, block.timestamp);
        }
    }

    // IERC721Receiver and IERC1155Receiver functions

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}