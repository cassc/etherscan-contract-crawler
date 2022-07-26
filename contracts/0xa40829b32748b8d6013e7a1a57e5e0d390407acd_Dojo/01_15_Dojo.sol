// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Timpers
/// @title: The Dojo
/// @author: manifold.xyz

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//                                                 :%%%%%%%%%%%%%%%%%*                                               //
//                                           .-----=#################*-----:                                         //
//                                           :@@@@@%                 :@@@@@*                                         //
//                      .%%%%%%%%%%%%%%*  :%%#::::::                  :::::+%%+                                      //
//                   [email protected]@@@@@@@@@@@@@#--=##*     .--:     .--:        .--+##+--------:                             //
//                   :@@@%%%%%%%%%%%%%%%@@#        :@@%     [email protected]@#        :@@*  [email protected]@@@@@@@*                             //
//                 %@@%%%%%#.........%%%%%%@@#  :@@%[email protected]@@@@%++*@@#  :@@#...  [email protected]@@@@@@@@@@*                          //
//             [email protected]@@%%#++=         ++*%%%@@%==+%%#***%%%%%#**#%%#===**+     -**#@@@@@@@@%==:                       //
//             :@@@%%%%%#              :%%%%%%@@@[email protected]@@=====*@@%==*@@#           [email protected]@@@@@@@@@@+                       //
//             :@@@%%#...               ..-%%%@@@[email protected]@@=====*@@%==*@@#     =%%%%%*[email protected]@@@@@%%*                    //
//             :@@@%%*                    :%%%@@@==+%%#=====+%%#==*@@#     [email protected]@%**=     :**#@@@@@#                    //
//             :@@@%%*                    :%%%@@@=================*@@#     [email protected]@*           [email protected]@@@@#                    //
//             :@@@%%*                    :%%%@@@**#@@@@@@@@@@@%**#@@#     [email protected]@@%%+        [email protected]@@@@#                    //
//             :@@@%%#--:              .--=%%%@@@%%%@@@@@@@@@@@%%%###+     -#####+--:     [email protected]@@@@#                    //
//             :@@@%%%%%#              :%%%%%%%%%@@@###########%@@#              [email protected]@*     [email protected]@@@@#                    //
//                 @@@%%%%%#         %%%%%%%%%@@%  :@@@@@@@@@@@#                 [email protected]@*  [email protected]@@@@@@@#                    //
//                 +**@%%%%#---------%%%%%%%%@@@%  :********#@@%==-  .=====:     [email protected]@#==*@@@@@%**=                    //
//                   :@@@%%%%%%%%%%%%%%%%%%@@@@@%........   [email protected]@@@@#  :@@@@@*   [email protected]@@@@@@@@@@+                       //
//                    ..:@@@@@@@@@@@@%%%@@@@@%[email protected]@@@@#..                        //
//                      .*********@@@%%@@@@@@%[email protected]@%**=                          //
//                               [email protected]@@@@@@@@@@%[email protected]@*                             //
//                                ..:@@@@@%:::.......................................::[email protected]@*                          //
//                                  .**#@@#..............:[email protected]@#                          //
//                                     :@@#[email protected]@@@@@@@@@@@@@@@@*[email protected]@#                          //
//                                     :@@#[email protected]@#                          //
//                                     :@@#[email protected]@#                          //
//                                     :@@#[email protected]@#                          //
//                                     :@@#[email protected]@#                          //
//                                     :@@#[email protected]@#                          //
//                                     :@@#[email protected]@#                          //
//                                     :@@#.......................:[email protected]@#                          //
//                                     :@@#.......................:==-.........:::[email protected]@#                          //
//                                     :@@#.......................:==-........:[email protected]@#                          //
//                                     :@@#.........===...........:==-........:[email protected]@#                          //
//                                     :@@#.........===...........:==-........:[email protected]@#                          //
//                                     :@@#.........===...........:==-........:[email protected]@#                          //
//                                     :@@#.........===...........:==-........:[email protected]@#                          //
//                                     :@@#.........===......:::..:==-........:==-...::[email protected]@#                          //
//                                     :@@#.........===.....:==-..:==-........:==-..:==*@@#                          //
//                                     :@@%===......===.....:==-..:==-........:==-..:==*@@#                          //
//                                     :@@%===...::-===.....:===::-==-........:===::-==*@@#                          //
//                                     :@@%===...======.....:========-........:========*@@#                          //
//                                     :@@%===...====================-..:==-..:========*@@#                          //
//                                     :@@%===---=====================---===---========*@@#                          //
//                                     :@@%============================================*@@#                          //
//                                     :@@%============================================*@@#                          //
//                                     .==+############################################*==-                          //
//                                        :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                             //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IDojo.sol";

contract Dojo is IDojo, ERC165, ReentrancyGuard, AdminControl {

    using Strings for uint256;
    using ECDSA for bytes32;

    string constant public override name = "Chimpers Dojo";
    string constant public override symbol = "CHIMPDOJO";

    // Token ID to owner
    mapping(uint256 => StakedOwner) private _owners;

    // Owner address to balance
    mapping(address => uint256) private _balances;

    // Token ID to XP
    mapping(uint256 => XP) private _xp;

    // Message nonces
    mapping(bytes32 => bool) private _usedNonces;

    // Chimpers Genesis contract address
    address private _chimpersGenesis;

    // Chimpers Generative contract address
    address private _chimpersGenerative;

    // Server oracle address
    address private _signingAddress;

    uint32 private _maxDailyXP;
    Bandana[] private _bandanas;
    
    string public baseURI;
    bool public dojoOpen;

    constructor(address chimpersGenesis, address chimpersGenerative) {
        _chimpersGenesis = chimpersGenesis;
        _chimpersGenerative = chimpersGenerative;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AdminControl, ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == _chimpersGenesis || msg.sender == _chimpersGenerative, "Invalid NFT");
        require(dojoOpen, "The Dojo has not been opened");

        // Genesis Chimpers token id maps 1:1
        uint256 stakedId = tokenId;

        if (msg.sender == _chimpersGenerative) {
            // Staked Generative Chimpers start at token id 10001
            stakedId += 10000;
        }

        _owners[stakedId] = StakedOwner(from, uint48(block.timestamp));
        _balances[from] += 1;

        // Award first bandana on initial deposit
        if (_xp[stakedId].value == 0) {
            _xp[stakedId].value = _bandanas[0].xpThreshold;
        }

        emit Transfer(address(0), from, stakedId);

        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _owners[tokenId].ownerAddress;
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_owners[tokenId].ownerAddress != address(0), "ERC721: invalid token ID");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev See {IDojo-setSigningAddress}.
     */
    function setSigningAddress(address signingAddress) external override adminRequired {
        _signingAddress = signingAddress;
    }

    /**
     * @dev See {IDojo-setTokenURI}.
     */
    function setTokenURI(string calldata uri) external override adminRequired {
        baseURI = uri;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override {
        _transferRevert();
    }

    function _transferRevert() private pure {
        revert("Cannot perform transfers on a non-transferable token");
    }

    function _translateTokenId(
        uint256 tokenId,
        bool isGenesisChimp
    ) private pure returns(uint256) {
        require(
            (tokenId >= 1 && tokenId <= 100) || 
            (!isGenesisChimp && tokenId >= 1 && tokenId <= 5555),
            "Invalid token ID"
        );
        return isGenesisChimp ? tokenId : tokenId + 10000;
    }

    function _validateSignature(
        uint256[] calldata tokenIds,
        uint32[] calldata amounts,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) private {
        uint256 length = tokenIds.length;
        
        // Verify nonce usage/re-use
        require(!_usedNonces[nonce], "Cannot replay transaction");

        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                (52+length*64).toString(),
                msg.sender,
                nonce,
                tokenIds,
                amounts
            )
        );
        require(message == expectedMessage, "Malformed message");

        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonce] = true;
    }


    /**
     * @dev See {IDojo-chimpXP}.
     */
    function chimpXP(
        uint256 tokenId,
        bool isGenesisChimp
    ) external view override returns(uint208) {
        uint256 stakedId = _translateTokenId(tokenId, isGenesisChimp);
        return _xp[stakedId].value;
    }


    /**
     * @dev See {IDojo-chimpBandana}.
     */
    function chimpBandana(
        uint256 tokenId,
        bool isGenesisChimp
    ) external view override returns(string memory) {
        uint256 stakedId = _translateTokenId(tokenId, isGenesisChimp);

        for (uint256 i = _bandanas.length; i > 0; i--) {
            if (_xp[stakedId].value >= _bandanas[i-1].xpThreshold) {
                return _bandanas[i-1].name;
            }
        }

        return "";
    }

    /**
     * @dev See {IDojo-bandanas}.
     */
    function bandanas() external view override returns(Bandana[] memory) {
        return _bandanas;
    }

    /**
     * @dev See {IDojo-setBandanas}.
     */
    function setBandanas(
        uint32[] calldata xpThresholds,
        string[] calldata bandanaNames
    ) external override adminRequired {
        uint256 numberOfBandanas = xpThresholds.length;

        for (uint256 i = 1; i < numberOfBandanas; i++) {
            require(xpThresholds[i] > xpThresholds[i-1], "Bandanas must be sorted");
        }

        delete _bandanas;

        for (uint256 i = 0; i < numberOfBandanas; i++) {
            _bandanas.push(Bandana({
                xpThreshold: xpThresholds[i],
                name: bandanaNames[i]
            }));
        }
    }

    /**
     * @dev See {IDojo-setMaxDailyXP}.
     */
    function setMaxDailyXP(uint32 xp) external override adminRequired {
        _maxDailyXP = xp;
    }

    /**
     * @dev See {IDojo-openDojo}.
     */
    function openDojo() external override adminRequired {
        dojoOpen = true;
    }

    /**
     * @dev See {IDojo-collectXP}.
     */
    function collectXP(
        uint256[] calldata dojoIds,
        uint32[] calldata amounts,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) public override {
        _validateSignature(dojoIds, amounts, message, signature, nonce);

        uint256 length = dojoIds.length;
        
        for (uint256 i = 0; i < length; i++) {
            uint256 id = dojoIds[i];
            require(_owners[id].ownerAddress != address(0), "ERC721: invalid token ID");

            uint256 daysElapsed = (
                block.timestamp - 
                (
                    _xp[id].lastUpdateTime == 0 ?
                    _owners[id].entryTime :
                    _xp[id].lastUpdateTime
                )
            ) / 86400;

            require(amounts[i] <= daysElapsed * _maxDailyXP, "Exceeds daily limit");
            _xp[id].lastUpdateTime = uint48(block.timestamp);
            _xp[id].value += amounts[i];
        }

        emit CollectedXP(msg.sender, dojoIds, amounts);
    }

    /**
     * @dev See {IDojo-enterDojo}.
     */
    function enterDojo(
        uint256[] calldata tokenIds,
        address[] calldata tokenAddresses
    ) external override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(tokenAddresses[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    /**
     * @dev See {IDojo-exitDojo}.
     */
    function exitDojo(
        uint256[] calldata dojoIds,
        uint32[] calldata xpList,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) external override nonReentrant {
        if (xpList.length > 0) {
            collectXP(dojoIds, xpList, message, signature, nonce);
        }

        uint256 length = dojoIds.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 id = dojoIds[i];
            require(msg.sender == _owners[id].ownerAddress, "Address is not owner");

            _owners[id].ownerAddress = address(0);
            _balances[msg.sender] -= 1;
            _xp[id].lastUpdateTime = 0;

            emit Transfer(msg.sender, address(0), id);

            // Return original chimp
            if (id <= 100) {
                IERC721(_chimpersGenesis).transferFrom(address(this), msg.sender, id);
            } else {
                IERC721(_chimpersGenerative).transferFrom(
                    address(this),
                    msg.sender,
                    id - 10000
                );
            }
        }
    }

    /**
     * @dev See {IDojo-returnLostChimp}.
     */
    function returnLostChimp(
        address to,
        bool isGenesisChimp,
        uint256 tokenId
    ) external override adminRequired {
        if (isGenesisChimp && _owners[tokenId].ownerAddress == address(0)) {
            IERC721(_chimpersGenesis).transferFrom(address(this), to, tokenId);
        } else if (!isGenesisChimp && _owners[tokenId+10000].ownerAddress == address(0)) {
            IERC721(_chimpersGenerative).transferFrom(address(this), to, tokenId);
        } else {
            revert("This chimp is not lost");
        }
    }

    /**
     * @dev See {IDojo-nonceUsed}.
     */
    function nonceUsed(bytes32 nonce) external view override returns(bool) {
        return _usedNonces[nonce];
    }
}