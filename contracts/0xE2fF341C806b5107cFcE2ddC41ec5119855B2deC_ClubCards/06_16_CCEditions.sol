// SPDX-License-Identifier: MIT
// Author: ClubCards
// Developed by Max J. Rux
// Dev Twitter: @Rux_eth

pragma solidity ^0.8.7;

// openzeppelin imports
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// local imports
import "../interfaces/ICCEditions.sol";

abstract contract CCEditions is ERC1155, Ownable, ICCEditions {
    using Strings for uint256;

    /*
     * Tracks waves.
     */
    mapping(uint256 => uint256) private _waves;
    /*
     * Tracks claims.
     */
    mapping(uint256 => uint72) private _claims;
    /*
     * Stores the provenance hash of each wave.
     *
     * Read about the importance of provenance hashes in
     * NFTs here: https://medium.com/coinmonks/the-elegance-of-the-nft-provenance-hash-solution-823b39f99473
     */
    mapping(uint256 => string) private waveProv;
    mapping(uint256 => string) private waveURI;
    mapping(uint256 => string) private claimURI;
    /*
     * Stores edition information for each tokenId
     *
     * Each index in tokens represents a tokenId.
     *
     * byte    1: Boolean to determine if a tokenId associates with a Wave
     *            or Claim.
     * bytes 2-3: EditionId(waveId/claimId)
     * bytes 4-5: TokenIdOfEdition
     */
    uint40[] private tokens;

    // track authorized transaction nonces
    mapping(address => uint256) private _authTxNonce;

    function setWaveStartIndex(uint256 waveId) external override {
        (
            ,
            uint256 MAX_SUPPLY,
            ,
            ,
            uint256 startIndex,
            uint256 startIndexBlock,
            ,
            ,
            ,
            ,

        ) = getWave(waveId);

        require(
            startIndexBlock != 0,
            "CCEditions: Starting index block not set"
        );
        require(startIndex == 0, "CCEditions: Starting index already set");
        bytes32 blockHash = blockhash(startIndexBlock);
        uint256 si = uint256(blockHash) % MAX_SUPPLY;
        if (blockHash == bytes32(0)) {
            si = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
        if (si == 0) {
            si += 1;
        }
        _waves[waveId] = _waves[waveId] |= si << 144;

        emit WaveStartIndexSet(waveId, si);
        delete si;
        delete blockHash;
    }

    function setWave(
        uint256 waveId,
        uint256 MAX_SUPPLY,
        uint256 REVEAL_TIMESTAMP,
        uint256 price,
        bool status,
        bool whitelistStatus,
        string calldata provHash,
        string calldata _waveURI
    ) external onlyTeam {
        require(!_waveExists(waveId), "CCEditions: Wave already exists");
        require(
            waveId <= type(uint8).max &&
                MAX_SUPPLY <= type(uint16).max &&
                REVEAL_TIMESTAMP <= type(uint56).max &&
                price <= type(uint64).max,
            "CCEditions: Value is too big!"
        );
        uint256 wave = waveId;
        wave |= MAX_SUPPLY << 8;
        wave |= REVEAL_TIMESTAMP << 24;
        wave |= price << 80;
        wave |= uint256(status ? 1 : 0) << 224;
        wave |= uint256(whitelistStatus ? 1 : 0) << 232;
        _waves[waveId] = wave;
        waveProv[waveId] = provHash;
        waveURI[waveId] = _waveURI;
    }

    function setWavePrice(uint256 waveId, uint256 newPrice) external onlyTeam {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        require(newPrice <= type(uint64).max, "CCEditions: Too high");
        (
            ,
            ,
            ,
            ,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            ,

        ) = getWave(waveId);

        uint256 wave = uint256(uint88(_waves[waveId]));
        wave |= newPrice << 80;
        wave |= startIndex << 144;
        wave |= startIndexBlock << 160;
        wave |= uint256(status ? 1 : 0) << 224;
        wave |= uint256(whitelistStatus ? 1 : 0) << 232;
        wave |= supply << 240;
        _waves[waveId] = wave;
    }

    function setWaveStatus(uint256 waveId, bool newStatus) external onlyTeam {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        (
            ,
            ,
            ,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            ,
            bool whitelistStatus,
            uint256 supply,
            ,

        ) = getWave(waveId);
        uint256 wave = uint256(uint88(_waves[waveId]));
        wave |= price << 80;
        wave |= startIndex << 144;
        wave |= startIndexBlock << 160;
        wave |= uint256(newStatus ? 1 : 0) << 224;
        wave |= uint256(whitelistStatus ? 1 : 0) << 232;
        wave |= supply << 240;
        _waves[waveId] = wave;
    }

    function setWaveWLStatus(uint256 waveId, bool newWLStatus)
        external
        onlyTeam
    {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        (
            ,
            ,
            ,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            ,
            uint256 supply,
            ,

        ) = getWave(waveId);
        uint256 wave = uint256(uint88(_waves[waveId]));
        wave |= price << 80;
        wave |= startIndex << 144;
        wave |= startIndexBlock << 160;
        wave |= uint256(status ? 1 : 0) << 224;
        wave |= uint256(newWLStatus ? 1 : 0) << 232;
        wave |= supply << 240;
        _waves[waveId] = wave;
    }

    function setWaveURI(uint256 waveId, string memory newURI)
        external
        onlyTeam
    {
        waveURI[waveId] = newURI;
    }

    function setClaimURI(uint256 claimId, string memory newURI)
        external
        onlyTeam
    {
        require(_claimExists(claimId), "ClaimId does not exist");
        require(claimId > 0, "ClaimId cannot be zero");
        claimURI[claimId] = newURI;
    }

    function setClaimStatus(uint256 claimId, bool newStatus) external onlyTeam {
        require(_claimExists(claimId), "ClaimId does not exist");
        require(claimId > 0, "ClaimId cannot be zero");
        (, , , uint256 supply, ) = getClaim(claimId);
        uint256 claim = uint40(_claims[claimId]);
        claim |= uint8(newStatus ? 1 : 0) << 40;
        claim |= supply << 48;
        _claims[claimId] = uint72(claim);
    }

    function setClaim(
        uint256 claimId,
        string memory uri,
        bool status
    ) external onlyTeam {
        require(!_claimExists(claimId), "CCEditions: Claim already exists");
        uint256 ti = totalSupply();
        require(
            claimId <= type(uint16).max && ti <= type(uint24).max,
            "CCEditions: Value is too big!"
        );
        uint256 claim = claimId;
        claim |= ti << 16;
        claim |= uint256(status ? 1 : 0) << 40;
        _claims[claimId] = uint72(claim);

        uint256 token = 1;
        token |= uint256(claimId << 8);
        tokens.push(uint40(token));
        claimURI[claimId] = uri;
        emit ClaimSet(ti, claimId);
    }

    function getClaim(uint256 claimId)
        public
        view
        override
        returns (
            uint256 CLAIM_INDEX,
            uint256 TOKEN_INDEX,
            bool status,
            uint256 supply,
            string memory uri
        )
    {
        require(_claimExists(claimId), "CCEditions: Claim does not exist");
        uint256 claim = _claims[claimId];
        CLAIM_INDEX = uint16(claim);
        TOKEN_INDEX = uint24(claim >> 16);
        status = uint8(claim >> 40) == 1;
        supply = uint24(claim >> 48);
        uri = claimURI[claimId];
    }

    function authTxNonce(address _address)
        public
        view
        override
        returns (uint256)
    {
        return _authTxNonce[_address];
    }

    function getToken(uint256 id)
        public
        view
        override
        returns (
            bool isClaim,
            uint256 editionId,
            uint256 tokenIdOfEdition
        )
    {
        require(_exists(id), "Token does not exist");
        (isClaim, editionId, tokenIdOfEdition) = _getToken(tokens[id]);
    }

    function totalSupply() public view override returns (uint256) {
        return tokens.length;
    }

    function getWave(uint256 waveId)
        public
        view
        override
        returns (
            uint256 WAVE_INDEX,
            uint256 MAX_SUPPLY,
            uint256 REVEAL_TIMESTAMP,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            string memory provHash,
            string memory _waveURI
        )
    {
        require(_waveExists(waveId), "CCEditions: Wave does not exist");
        uint256 wave = _waves[waveId];
        WAVE_INDEX = uint8(wave);
        MAX_SUPPLY = uint16(wave >> 8);
        REVEAL_TIMESTAMP = uint56(wave >> 24);
        price = uint64(wave >> 80);
        startIndex = uint16(wave >> 144);
        startIndexBlock = uint64(wave >> 160);
        status = uint8(wave >> 224) == 1;
        whitelistStatus = uint8(wave >> 232) == 1;
        supply = uint16(wave >> 240);
        provHash = waveProv[waveId];
        _waveURI = waveURI[waveId];
    }

    // check if tokenId exists
    function _exists(uint256 id) internal view returns (bool) {
        return id >= 0 && id < totalSupply();
    }

    function _setWaveStartIndexBlock(uint256 waveId) internal {
        (
            ,
            ,
            ,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            ,

        ) = getWave(waveId);

        if (startIndexBlock == 0) {
            uint256 bn = block.number;
            uint256 wave = uint256(uint88(_waves[waveId]));
            wave |= price << 80;
            wave |= startIndex << 144;
            wave |= bn << 160;
            wave |= uint256(status ? 1 : 0) << 224;
            wave |= uint256(whitelistStatus ? 1 : 0) << 232;
            wave |= supply << 240;
            _waves[waveId] = wave;

            emit WaveStartIndexBlockSet(waveId, bn);
        }
    }

    function _checkReveal(uint256 waveId) internal {
        (
            ,
            uint256 MAX_SUPPLY, // 16
            uint256 REVEAL_TIMESTAMP, // 64
            ,
            uint256 startIndex, // 8
            ,
            ,
            ,
            uint256 supply,
            ,

        ) = getWave(waveId);
        if (
            startIndex == 0 &&
            ((supply == MAX_SUPPLY) || block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            _setWaveStartIndexBlock(waveId);
        }
    }

    function _getURI(uint256 id) internal view returns (string memory) {
        require(_exists(id), "CCEditions: TokenId does not exist");
        (bool isClaim, uint256 editionId, uint256 tokenIdOfEdition) = _getToken(
            tokens[id]
        );
        if (isClaim) {
            return claimURI[editionId];
        } else {
            return
                string(
                    abi.encodePacked(
                        waveURI[editionId],
                        tokenIdOfEdition.toString()
                    )
                );
        }
    }

    // check if a wave exists
    function _waveExists(uint256 waveId) internal view returns (bool) {
        return _waves[waveId] != 0;
    }

    // check if a claim exists
    function _claimExists(uint256 claimId) internal view returns (bool) {
        return _claims[claimId] != 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            uint256 edId = st2num(string(data));

            if (edId == 0) {
                for (uint256 i = 0; i < ids.length; i++) {
                    (bool isClaim, uint256 claimId, ) = _getToken(
                        tokens[ids[i]]
                    );
                    require(isClaim, "Token is not claimable");
                    _increaseClaimSupply(claimId, amounts[i]);
                }
                emit Claimed(to, _authTxNonce[to], ids, amounts);
            } else {
                for (uint256 i = 0; i < ids.length; i++) {
                    require(!_exists(ids[i]), "Token already exists");
                    require(amounts[i] == 1, "Invalid mint amount");
                }
                if (_increaseWaveSupply(edId, ids.length)) {
                    _authTxNonce[to]++;
                    emit WhitelistMinted(
                        to,
                        ids.length,
                        edId,
                        _authTxNonce[to]
                    );
                }
            }
        }
    }

    function _getToken(uint256 tokenData)
        private
        pure
        returns (
            bool isClaim,
            uint256 editionId,
            uint256 tokenIdOfEdition
        )
    {
        isClaim = uint8(tokenData) == 1;
        editionId = uint16(tokenData >> 8);
        tokenIdOfEdition = uint16(tokenData >> 24);
    }

    function _increaseClaimSupply(uint256 claimId, uint256 amount) private {
        (, , bool status, uint256 supply, ) = getClaim(claimId);
        require(status, "Claim is paused");
        uint256 temp = _claims[claimId];
        temp = uint256(uint48(temp));
        temp |= uint256(supply + amount) << 48;
        _claims[claimId] = uint72(temp);
    }

    function st2num(string memory numString) private pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            val += (uint256(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function _increaseWaveSupply(uint256 waveId, uint256 numMints)
        private
        returns (bool)
    {
        (, , , , , , , bool whitelistStatus, uint256 supply, , ) = getWave(
            waveId
        );
        uint256 temp = _waves[waveId];
        temp = uint256(uint240(temp));
        _waves[waveId] = temp |= uint256(supply + numMints) << 240;
        for (uint256 i = 0; i < numMints; i++) {
            temp = 0;
            temp |= uint24(waveId << 8);
            temp |= uint40((supply + i) << 24);
            tokens.push(uint40(temp));
        }
        return whitelistStatus;
    }
}