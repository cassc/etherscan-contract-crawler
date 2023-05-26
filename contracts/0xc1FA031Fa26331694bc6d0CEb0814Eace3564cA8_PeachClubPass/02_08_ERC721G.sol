pragma solidity ^0.8.15;

import "./erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// G is short for Guard
contract ERC721G is ERC721A, Ownable {

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    // =============================================================
    // Token Guard Begin
    // =============================================================
    modifier onlyOracle() {
        require(msg.sender == _oracle(), "ORACLE_ONLY");
        _;
    }

    function enableGuardMode(address oracle) external onlyOwner() {
        mode = GUARDMODE.RUN;
        __setOracle(oracle);
        bigbro = BigBroOracle(oracle);
    }

    function turboGuardMode(bool turbo) external onlyOwner() {
        if (mode != GUARDMODE.PAUSE) {
            mode = turbo ? GUARDMODE.TURBO : GUARDMODE.RUN;
        }
    }

    function disableGuardMode() external onlyOwner() {
        mode = GUARDMODE.PAUSE;
        __setOracle(address(0));
    }

    function getTokenState(uint256 tokenId) external view returns(bool, TOKENSTATE) {
        return (_tokenGuardService[tokenId], _tokenStates[tokenId]);
    }

    /**
     * Token Guard operations
     */
    function queryResponseDispatch(
        REPLYACT  res,
        address   addr, // for compatible to BigBroOracle
        uint256[] calldata tokenIds
    ) external onlyOracle {
        uint length = tokenIds.length;
        for (uint i; i < length; ++i) {
            uint256 tokenId = tokenIds[i];
            
            if (res == REPLYACT.UNLOCK) {
                // unlock token
                _normalToken(tokenId);
            } else if (res == REPLYACT.LOCK){
                // lock token
                _lockToken(tokenId);
            } else if (res == REPLYACT.GUARD) {
                // guard
                _tokenGuardService[tokenId] = true;
                _lockToken(tokenId);
            } else if (res == REPLYACT.UNGUARD) {
                // unguard
                delete _tokenGuardService[tokenId];
                _normalToken(tokenId);
            } else {
                revert("Nothong to do");
            }
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        if (mode != GUARDMODE.PAUSE && _tokenGuardService[startTokenId]) {
            for (uint i = startTokenId; i < startTokenId + quantity; ++i) {
                _lockToken(i);
            }
            bigbro.riskRequest(from, to, startTokenId, quantity);
        }
    }

    function bigbroApprovalForAll(address msg_sender, address operator) external onlyOracle {
        if (operator == msg_sender) revert ApproveToCaller();

        _setOperatorApprpvals(msg_sender, operator);
        emit ApprovalForAll(_msgSenderERC721A(), operator, true);
    }
}