import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

error ApproveToCaller();

interface IToken {
    function mint(address to, uint256 quantity) external;

    function totalMinted() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

struct Phase {
    //
    // The identifier of a phase.
    string id;
    //
    // The root of the Merkle tree which contains an allowlist of wallets and quantities (address,uint64) that
    // can mint for free.
    bytes32 merkleRoot;
    //
    // When is minting for this phase allowed to begin.
    uint32 startTime;
    //
    // When minting for this phase ends. (If 0, no end boundary.)
    uint32 endTime;
    //
    // The amount of tokens a user can mint in this phase. This value is only checked when
    // the merkle root is null.
    uint32 walletLimit;
}

contract Mint is Ownable {
    address private _tokenAddress;

    bool private _enabled;
    Phase[] private _phases;

    mapping(bytes32 => bool) private _usedLeaves;
    mapping(address => bool) private _usedPublicMints;

    function setTokenAddress(address addr) public onlyOwner {
        _tokenAddress = addr;
    }

    function tokenAddress() public view returns (address) {
        return _tokenAddress;
    }

    function enabled() public view returns (bool) {
        return _enabled;
    }

    function setEnabled(bool b) public onlyOwner {
        _enabled = b;
    }

    function setPhases(Phase[] memory phases) public onlyOwner {
        delete _phases;

        for (uint256 i = 0; i < phases.length; i++) {
            _phases.push(phases[i]);
        }
    }

    function currentPhase() public view returns (Phase memory phase, bool ok) {
        for (uint64 i = 0; i < _phases.length; i++) {
            if (
                block.timestamp >= _phases[i].startTime &&
                (block.timestamp < _phases[i].endTime ||
                    _phases[i].endTime == 0)
            ) {
                return (_phases[i], true);
            }
        }

        return (phase, false);
    }

    function allowlistMint(
        address to,
        uint64 quantity,
        bytes32[] memory proof
    ) public {
        require(_tokenAddress != address(0), "Token address not set.");

        require(_enabled == true, "Minting is not enabled.");

        (Phase memory current, bool ok) = currentPhase();
        require(ok == true, "Minting is not open.");

        bytes32 leaf = makeMerkleLeaf(_msgSender(), quantity);

        require(
            MerkleProof.verify(proof, current.merkleRoot, leaf),
            "Address/quantity combination not on allowlist."
        );

        require(_usedLeaves[leaf] == false, "Mint already used.");

        _usedLeaves[leaf] = true;

        IToken(_tokenAddress).mint(to, quantity);
    }

    function publicMint(address to, uint64 quantity) public {
        require(_tokenAddress != address(0), "Token address not set.");

        require(_enabled == true, "Minting is not enabled.");

        (Phase memory current, bool ok) = currentPhase();
        require(ok == true, "Minting is not yet open.");

        require(current.merkleRoot == 0, "Public phase not open.");

        require(
            IToken(_tokenAddress).balanceOf(to) + quantity <=
                current.walletLimit,
            "Mint would exceed wallet limit."
        );

        require(_usedPublicMints[to] == false, "Recipient has already minted.");
        require(
            _usedPublicMints[_msgSender()] == false,
            "Recipient has already minted."
        );

        _usedPublicMints[_msgSender()] = true;
        if (_msgSender() != to) {
            _usedPublicMints[to] = true;
        }

        IToken(_tokenAddress).mint(to, quantity);
    }

    function adminMint(address to, uint64 quantity) public onlyOwner {
        require(_tokenAddress != address(0), "Token address not set.");

        IToken(_tokenAddress).mint(to, quantity);
    }

    function totalMinted() public view returns (uint256) {
        require(_tokenAddress != address(0), "Token address not set.");

        return IToken(_tokenAddress).totalMinted();
    }

    function makeMerkleLeaf(address wallet, uint64 quantity)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(wallet, quantity));
    }

    function leafUsed(bytes32 leaf) public view returns (bool) {
        return _usedLeaves[leaf];
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(_tokenAddress != address(0), "Token address not set.");

        return IToken(_tokenAddress).balanceOf(owner);
    }
}

interface IMint {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function enabled() external view returns (bool);

    function currentPhase() external view returns (Phase memory phase, bool ok);

    function allowlistMint(
        address to,
        uint64 quantity,
        bytes32[] memory proof
    ) external;

    function publicMint(address to, uint64 quantity) external;

    function balanceOf(address owner) external view returns (uint256);

    function leafUsed(bytes32 leaf) external view returns (bool);

    function totalMinted() external view returns (uint256);
}