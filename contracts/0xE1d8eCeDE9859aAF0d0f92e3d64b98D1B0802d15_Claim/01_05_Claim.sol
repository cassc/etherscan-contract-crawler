// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IGasPrice {
    function latestAnswer() external view returns (int256);
}

interface IClaimPass {
    // Can use this to check and see if we have the right approvals.
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    // Will call this from the UI.
    function setApprovalForAll(address operator, bool approved) external;

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 id) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external;
}

interface ILostMiner {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external;
}

interface IClaim {
    function claim(
        uint256[] calldata claimPassIDs,
        uint256[] calldata lostMinerIDs,
        bytes calldata signature,
        address dest
    ) external;

    function status() external returns (Status memory);

    function gasPrice() external returns (uint256);
}

struct Status {
    bool open;
    bool enabled;
    uint64 openAt;
    uint64 closesAt;
}

contract Claim is Ownable {
    address _claimPassContract;
    address _lostMinerContract;
    address _txnSigner;
    address _gasPricer;

    bool _claimEnabled = false;
    uint64 _claimStarts = 0;
    uint64 _claimEnds = 0;

    function setClaimPassContract(address addr) public onlyOwner {
        _claimPassContract = addr;
    }

    function setLostMinerContract(address addr) public onlyOwner {
        _lostMinerContract = addr;
    }

    function setTxnSigner(address addr) public onlyOwner {
        _txnSigner = addr;
    }

    function setClaimEnabled(bool b) public onlyOwner {
        _claimEnabled = b;
    }

    function setClaimWindow(uint64 start, uint64 end) public onlyOwner {
        _claimStarts = start;
        _claimEnds = end;
    }

    function setGasPricer(address addr) public onlyOwner {
        _gasPricer = addr;
    }

    function gasPrice() public view returns (uint256) {
        if (_gasPricer == address(0)) {
            return 0;
        }

        return uint256(IGasPrice(_gasPricer).latestAnswer());
    }

    function status() public view returns (Status memory) {
        return
            Status({
                open: claimIsOpen(),
                enabled: _claimEnabled,
                openAt: _claimStarts,
                closesAt: _claimEnds
            });
    }

    function claimIsOpen() internal view returns (bool) {
        if (!_claimEnabled) {
            return false;
        }

        if (_claimStarts == 0 || block.timestamp < _claimStarts) {
            return false;
        }

        if (_claimEnds == 0 || block.timestamp >= _claimEnds) {
            return false;
        }

        return true;
    }

    function claim(
        uint256[] calldata claimPassIDs,
        uint256[] calldata lostMinerIDs,
        bytes calldata signature,
        address dest
    ) public {
        ILostMiner lostMiner = ILostMiner(_lostMinerContract);
        IClaimPass claimPass = IClaimPass(_claimPassContract);

        require(claimPassIDs.length == lostMinerIDs.length, "Array mismatch");

        require(_claimEnabled, "Claim not enabled");

        require(
            _claimStarts > 0 && block.timestamp >= _claimStarts,
            "Claim window hasn't opened"
        );

        require(
            _claimEnds > 0 && block.timestamp < _claimEnds,
            "Claim window is closed"
        );

        require(
            _claimPassContract != address(0) &&
                _lostMinerContract != address(0),
            "Claim pass/token not configured"
        );

        require(
            dest != address(0),
            "Destination address cannot be the zero address"
        );

        require(
            claimPass.isApprovedForAll(_msgSender(), address(this)),
            "Approval required"
        );

        require(
            verifySignature(
                signature,
                getHash(getDigest(claimPassIDs, lostMinerIDs))
            ),
            "Signature mismatch"
        );

        for (uint256 i = 0; i < claimPassIDs.length; i++) {
            uint256 passID = claimPassIDs[i];
            uint256 minerID = lostMinerIDs[i];

            claimPass.safeTransferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                passID
            );

            lostMiner.safeTransferFrom(_lostMinerContract, dest, minerID);
        }
    }

    function devclaim(
        uint256[] calldata claimPassIDs,
        uint256[] calldata lostMinerIDs,
        bytes calldata signature,
        address dest
    ) public {
        ILostMiner lostMiner = ILostMiner(_lostMinerContract);
        IClaimPass claimPass = IClaimPass(_claimPassContract);

        require(claimPassIDs.length == lostMinerIDs.length, "Array mismatch");

        require(
            _claimPassContract != address(0) &&
                _lostMinerContract != address(0),
            "Claim pass/token not configured"
        );

        require(
            claimPass.isApprovedForAll(_msgSender(), address(this)),
            "Approval required"
        );

        require(
            verifySignature(
                signature,
                getHash(getDigest(claimPassIDs, lostMinerIDs))
            ),
            "Signature mismatch"
        );

        for (uint256 i = 0; i < claimPassIDs.length; i++) {
            uint256 passID = claimPassIDs[i];
            uint256 minerID = lostMinerIDs[i];

            claimPass.safeTransferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                passID
            );

            lostMiner.safeTransferFrom(_lostMinerContract, dest, minerID);
        }
    }

    function verifySignature(bytes memory signature, bytes32 digestHash)
        public
        view
        returns (bool)
    {
        address std = getSigner(signature, digestHash);
        if (std == _txnSigner) {
            return true;
        }

        address packed = getSignerPacked(signature, digestHash);
        if (packed == _txnSigner) {
            return true;
        }

        return false;
    }

    function getSigner(bytes memory signature, bytes32 digestHash)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        bytes32 ethSignedHash = getMessageHash(digestHash);
        return ecrecover(ethSignedHash, v, r, s);
    }

    function getSignerPacked(bytes memory signature, bytes32 digestHash)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        bytes32 ethSignedHash = getMessageHashPacked(digestHash);
        return ecrecover(ethSignedHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getMessageHash(bytes32 digestHash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode("\x19Ethereum Signed Message:\n32", digestHash)
            );
    }

    function getMessageHashPacked(bytes32 digestHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", digestHash)
            );
    }

    function getHash(bytes memory digest) public pure returns (bytes32 hash) {
        return keccak256(digest);
    }

    function getDigest(
        uint256[] calldata claimPassIDs,
        uint256[] calldata lostMinerIDs
    ) public pure returns (bytes memory) {
        return abi.encode(claimPassIDs, lostMinerIDs);
    }
}