/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

// File: contracts/test/contracts/src/module/MerkleProof.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: contracts/test/contracts/src/ERC/IERC20.sol

pragma solidity 0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/test/contracts/src/data/Project.sol

pragma solidity 0.8.12;

contract Project {
    event OwnerChangedEvent(address caller, address newOwner);
    event ProjectFeeChangedEvent(
        address caller,
        address feeToken,
        uint feeAmount
    );

    address owner;

    uint public fee; 
    address public feeToken; 

    constructor() {
        owner = msg.sender;
    }


    mapping(address => uint) public deflationContract;
    mapping(address => uint) public deflationUser;

    mapping(address => bool) public isProjectInit; 

    mapping(address => address) public project; 
    mapping(address => address) public projectOwner; 
    mapping(address => uint) public projectAmount; 

    mapping(address => uint) public startTime; 
    mapping(address => uint) public endTime; 
    mapping(address => uint) public freeLineTime; 

    
    mapping(address => address) public invest; 
    mapping(address => uint) public investBuyMax; 
    mapping(address => uint) public investBuyMin; 
    mapping(address => uint) public investAmount; 
    
    mapping(address => uint) public investToOwner; 
    mapping(address => uint) public projectPoolTotal; 
    mapping(address => uint) public ratio; 

    function initProjectInfo(
        address[] memory addresss,
        uint[] memory uints
    ) external {
        require(isProjectInit[addresss[0]] == false, "project init");

        bool isSendFee = true;
        address projectAddress = addresss[0];
        uint amount = uints[0];

        bool isAddTokenOutSuccess = IERC20(projectAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (fee != 0) {
            isSendFee = IERC20(feeToken).transferFrom(msg.sender, owner, fee);
        }

        calculDeflationRatio(projectAddress);

        if (deflationContract[projectAddress] != 0) {
            amount = uint(
                (amount * (10 ** 18 - deflationContract[projectAddress])) /
                    (10 ** 18)
            );
        }

        if (isAddTokenOutSuccess && isSendFee) {
            projectPoolTotal[projectAddress] =
                amount -
                (1000 *
                    (deflationContract[projectAddress] +
                        deflationUser[projectAddress])) /
                10 ** 18 -
                2; 
            _projectBaseConfig(projectAddress, addresss, uints);
        }
    }

    function _projectBaseConfig(
        address projectAddress,
        address[] memory addresss,
        uint[] memory uints
    ) internal {
        /* address */
        project[projectAddress] = addresss[0];
        projectOwner[projectAddress] = addresss[1];
        invest[projectAddress] = addresss[2];
        /* uint */
        projectAmount[projectAddress] = uints[0];
        startTime[projectAddress] = uints[1];
        endTime[projectAddress] = uints[2];
        freeLineTime[projectAddress] = uints[3];
        investBuyMax[projectAddress] = uints[4];
        investBuyMin[projectAddress] = uints[5];
        investAmount[projectAddress] = uints[6];
        isProjectInit[projectAddress] = true;
        ratio[projectAddress] = uint((uints[0] * 10 ** 18) / uints[6]);

        
        if (deflationContract[projectAddress] != 0) {
            investAmount[projectAddress] =
                (uints[6] * (10 ** 18 - deflationContract[projectAddress])) /
                (10 ** 18);
            ratio[projectAddress] = uint(
                (projectPoolTotal[projectAddress] * 10 ** 18) / uints[6]
            );
        }

        require(ratio[projectAddress] != 0);
    }

    function calculDeflationRatio(address token) internal {
        IERC20 Token = IERC20(token);

        
        uint calContractBefore = Token.balanceOf(address(this));
        Token.approve(address(this), 1000);
        Token.transferFrom(address(this), address(this), 1000);
        uint calContractAfter = Token.balanceOf(address(this));
        deflationContract[token] =
            ((calContractBefore - calContractAfter) * 10 ** 18) /
            1000;

        
        uint calUserBefore = Token.balanceOf(address(this));
        Token.transfer(address(this), 1000);
        uint calUserAfter = Token.balanceOf(address(this));
        deflationUser[token] =
            ((calUserBefore - calUserAfter) * 10 ** 18) /
            1000;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChangedEvent(msg.sender, _owner);
    }

    function setFee(uint _feeAmount, address _feeToken) external onlyOwner {
        fee = _feeAmount;
        feeToken = _feeToken;
        emit ProjectFeeChangedEvent(msg.sender, _feeToken, _feeAmount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyProjectOwner(address _project) {
        address _owner = projectOwner[_project];
        require(_owner == msg.sender, "not owner");
        _;
    }
}

// File: contracts/test/contracts/src/module/WhiteList.sol


pragma solidity 0.8.12;


contract WhiteList is Project {
    mapping(address => bool) public isWhiteProject;
    mapping(address => bytes32) public whiteRoot;
    mapping(address => uint) public whiteTotal; 
    mapping(address => uint) public whiteMaxBuy;

    mapping(address => uint) public whiteReserve; 
    mapping(address => uint) public whiteHasInvest; 

    mapping(address => uint) public userResrve; 
    mapping(address => uint) public userHasInvest; 

    mapping(address => uint) public deflation; 

    function setProjectWhite(
        address _project,
        bytes32 _root,
        uint _maxBuy,
        uint _totalUsers
    ) public onlyProjectOwner(_project) {
        
        require(
            _totalUsers * _maxBuy <=
                investAmount[_project] - investToOwner[_project],
            "user could max buy overflow coin pool"
        );
        isWhiteProject[_project] = true;
        whiteRoot[_project] = _root;
        whiteTotal[_project] = _totalUsers;
        whiteMaxBuy[_project] = _maxBuy;
        whiteReserve[_project] = _totalUsers * _maxBuy;
        userResrve[_project] = investAmount[_project] - _totalUsers * _maxBuy;
    }

    
    function isWhite(
        address _project,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        return MerkleProof.verify(_proof, whiteRoot[_project], keccak256(abi.encodePacked(msg.sender)));
    }
}

// File: contracts/test/contracts/src/data/User.sol

pragma solidity 0.8.12;

contract User is WhiteList {
    event InitWhiteInvestEvent(address indexed project, address indexed investor, uint amount);
    struct UserStruct {
        address project;
        address invest;
        address user; 
        uint investTotal; 
        uint reward; 
        uint hasReward; 
    }

    
    mapping(address => mapping(address => uint)) userProjectType;

    
    mapping(address => mapping(address => UserStruct))
        public userInvitests; 

    function initWhiteInvest(
        address project,
        address _invest,
        uint investTotal,
        bytes32[] memory _proof
    ) external {
        require(
            userProjectType[msg.sender][project] == 0 ||
                userProjectType[msg.sender][project] == 1,
            "nonwhitelist investors"
        ); // 0 default; 1 whitelist accounts
        require(_invest == invest[project], "token not matching");
        uint nowTime = block.timestamp;
        UserStruct memory userInfo = userInvitests[msg.sender][project];

        bool userIsWhite = isWhite(project, _proof);

        require(userIsWhite, "you are not members of whitelists");

        
        require(
            whiteReserve[project] - whiteHasInvest[project] >= investTotal,
            "not enough project token"
        );

        
        uint userInvestTotal = userInfo.investTotal + investTotal;
        require(
            userInvestTotal <= whiteMaxBuy[project],
            "invest buy range overflow"
        );

        
        require(
            startTime[project] <= nowTime && endTime[project] >= nowTime,
            "invest time overflow"
        );

        
        bool isInverstSuccess = IERC20(_invest).transferFrom(
            msg.sender,
            address(this),
            investTotal
        );

        
        if (isInverstSuccess) {
            _initUserBaseConfig(project, _invest);
            userInvitests[msg.sender][project].investTotal = userInvestTotal; 
            userInvitests[msg.sender][project].reward =
                (ratio[project] * userInvestTotal) /
                10 ** 18; 
            investToOwner[project] += investTotal; 
            projectPoolTotal[project] -=
                (investTotal * ratio[project]) /
                10 ** 18; 
            whiteHasInvest[project] += investTotal; 
        }

        userProjectType[msg.sender][project] = 1;
        emit InitWhiteInvestEvent(project, _invest,investTotal);
    }

    function initUserInvest(
        address project,
        address _invest,
        uint investTotal
    ) external {
        require(
            userProjectType[msg.sender][project] == 0 ||
                userProjectType[msg.sender][project] == 2,
            "nonordinary investors"
        ); // 0 default; 2 ordinary accounts
        require(_invest == invest[project], "token not matching");
        uint nowTime = block.timestamp;
        UserStruct memory userInfo = userInvitests[msg.sender][project];
        
        if (isWhiteProject[project]) {
            require(
                userResrve[project] - userHasInvest[project] >= investTotal,
                "not enough project token"
            );
        } else {
            require(
                projectPoolTotal[project] -
                    (investTotal * ratio[project]) /
                    10 ** 18 >=
                    0,
                "not enough project token"
            );
        }

        
        uint userInvestTotal = userInfo.investTotal + investTotal;
        require(
            userInvestTotal >= investBuyMin[project] &&
                userInvestTotal <= investBuyMax[project],
            "invest buy range overflow"
        );

        
        require(
            startTime[project] <= nowTime && endTime[project] >= nowTime,
            "invest time overflow"
        );

        
        bool isInverstSuccess = IERC20(_invest).transferFrom(
            msg.sender,
            address(this),
            investTotal
        );

        
        if (isInverstSuccess) {
            _initUserBaseConfig(project, _invest);
            userInvitests[msg.sender][project].investTotal = userInvestTotal; 
            userInvitests[msg.sender][project].reward =
                (ratio[project] * userInvestTotal) /
                10 ** 18; 
            investToOwner[project] += investTotal; 
            projectPoolTotal[project] -=
                (investTotal * ratio[project]) /
                10 ** 18; 
            userHasInvest[project] += investTotal; 
        }

        userProjectType[msg.sender][project] = 2;
        emit InitWhiteInvestEvent(project, _invest,investTotal);
    }

    function _initUserBaseConfig(address project, address invest) private {
        userInvitests[msg.sender][project].project = project;
        userInvitests[msg.sender][project].invest = invest;
        userInvitests[msg.sender][project].user = msg.sender;
    }
}


pragma solidity 0.8.12;

contract Main is User {
    event UserWithdrawEvent(
        address indexed caller,
        address indexed token,
        uint amount
    );
    event ProjectWithdraw(
        address indexed caller,
        address indexed project,
        address indexed token,
        uint amount
    );

    
    function userCanWithdraw(address _project) public view returns (uint) {
        if (endTime[_project] > block.timestamp) {
            return 0;
        }
        if (
            freeLineTime[_project] == 0 ||
            block.timestamp - endTime[_project] >= freeLineTime[_project]
        ) {
            return
                userInvitests[msg.sender][_project].reward -
                userInvitests[msg.sender][_project].hasReward;
        } else {
            return
                (((block.timestamp - endTime[_project]) *
                    userInvitests[msg.sender][_project].reward) /
                    freeLineTime[_project]) -
                userInvitests[msg.sender][_project].hasReward;
        }
    }


    function userWithdraw(address _project) external returns (bool) {
        uint canWithdraw = userCanWithdraw(_project);
        userInvitests[msg.sender][_project].hasReward += canWithdraw;
        emit UserWithdrawEvent(msg.sender, _project, canWithdraw);
        return IERC20(_project).transfer(msg.sender, canWithdraw);
    }


    function projectWithdraw(
        address _project
    ) external onlyProjectOwner(_project) returns (bool) {
        require(endTime[_project] < block.timestamp); 
        uint investCanWithdraw = investToOwner[_project];
        uint projectCanWithdraw = projectPoolTotal[_project];
        investToOwner[_project] = 0; 
        projectPoolTotal[_project] = 0; 
        IERC20(invest[_project]).transfer(msg.sender, investCanWithdraw);
        IERC20(_project).transfer(msg.sender, projectCanWithdraw);

        emit ProjectWithdraw(
            msg.sender,
            _project,
            _project,
            projectCanWithdraw
        );
        emit ProjectWithdraw(
            msg.sender,
            _project,
            invest[_project],
            investCanWithdraw
        );

        return true;
    }

    fallback() external payable {}

    receive() external payable {}
}