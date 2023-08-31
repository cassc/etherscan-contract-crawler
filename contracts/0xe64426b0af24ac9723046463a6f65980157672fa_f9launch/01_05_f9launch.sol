//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract f9launch is ERC20 {
  uint256 public startTimestamp; // same timestamp as the end of the IDO (claim time)

  address public f9launchTeam;
  address public liquidityPoolCreator;
  address public launchpad;

  bool private _lock;

  constructor(
    address _liquidityPoolCreator,
    address _operationsActive,
    address _f9launchTeam,
    address _rewards,
    address _f9,
    uint256 _startTimestamp
  ) ERC20("Falcon Heavy", "wF9") {
    f9launchTeam = _f9launchTeam;
    startTimestamp = _startTimestamp;
    liquidityPoolCreator = _liquidityPoolCreator;

    // totalSupply: 999999 * 1e18

    _mint(liquidityPoolCreator, 299999 * 1e18); // 30% Pools
    _mint(_operationsActive, 189999 * 1e18); // 19% Charity
    _mint(f9launchTeam, 29999 * 1e18); // 3% Marketing
    _mint(_rewards, 29999 * 1e18); // 3% Rewards
    _mint(_f9, 29999 * 1e18); // 3% F9 DEVS

    // _mint(_launchpad, 420004 * 1e18); // 42% -> check setLaunchpad
  }

  modifier onlyf9launchTeam() {
    require(_msgSender() == f9launchTeam, "Not Authorized");
    _;
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    require(
      block.timestamp >= startTimestamp ||
        _msgSender() == liquidityPoolCreator ||
        _msgSender() == launchpad,
      "Wait for IDO to finish"
    );
    return super.transfer(to, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    require(
      block.timestamp >= startTimestamp ||
        from == liquidityPoolCreator ||
        _msgSender() == launchpad,
      "Wait for IDO to finish"
    );
    return super.transferFrom(from, to, amount);
  }

  function setStartTimestamp(uint256 _newStart) external {
    require(_msgSender() == address(launchpad), "Only IDO");
    require(_newStart >= block.timestamp, "New time is in the past");
    startTimestamp = _newStart;
  }

  function setLaunchpad(address _launchpadAddress) external onlyf9launchTeam {
    launchpad = _launchpadAddress;
    if (!_lock) {
      _mint(_launchpadAddress, 420004 * 1e18); // 42% F9 Launchpad
      _lock = true;
    }
  }

  function setf9launchTeam(address newf9launchTeam) external onlyf9launchTeam {
    f9launchTeam = newf9launchTeam;
  }
}

// In the bustling city of New Amsterdam, a remarkable movement has emerged, captivating the hearts and minds of a diverse array of individuals. This group, known as the F9 Space Cult, embodies a spirit of idealism and determination, united in their mission to champion decentralized finance (DeFi) and the ascent of Decentralized Autonomous Organizations (DAOs) across the globe.

// Once a stronghold of corporate dominance, New Amsterdam has undergone a remarkable transformation. It has become a fertile ground for a burgeoning resistance movement, driven by the F9 Space Cult's unwavering belief that centralized systems hinder humanity's true potential.

// Led by an enigmatic and visionary figure, whose identity remains shrouded in mystery, the F9 Space Cult has harnessed the power of unity and collective purpose. Their magnetic appeal draws in individuals from all walks of life, disillusioned by the power games orchestrated by corporations and governments.

// Deep within the city's tapestry, nestled on the outskirts, lies the headquarters of the F9 Space Cult—an abandoned server resurrected into a sanctuary of innovation and experimentation. Here, like-minded souls converge to exchange ideas, challenge existing power structures, and collectively forge a path towards a more equitable future.

// As the F9 Space Cult gains momentum, its presence resonates with both supporters and adversaries. The corporate elite, threatened by the surging tide of DeFi and DAOs, perceive the cult as a force to be extinguished. In response, they launch a campaign of misinformation, painting the F9 Space Cult as a band of anarchists hell-bent on sowing chaos in society.

// Yet, undeterred by these attacks, the F9 Space Cult and its passionate followers remain steadfast in their conviction that decentralization is the key to unlocking a fairer and more inclusive world. Through a series of enlightening meetups and immersive workshops, they diligently educate the public about the transformative potential of DeFi and DAOs. Their message reverberates, spreading like wildfire, captivating an ever-widening audience.

// Within this awe-inspiring journey, an unprecedented breakthrough occurs. A brilliant young programmer steps forward, wielding a revolutionary blockchain technology capable of democratizing access to decentralized finance and empowering the creation of autonomous organizations. Her creation, the F9 Rocket System, emerges as a game-changer—a decentralized platform that simplifies the creation and management of DAO-governed structures, propelling the movement to new heights.

// Presenting this groundbreaking innovation to the F9 Space Cult, she sparks a fusion of awe and inspiration within their ranks. Recognizing the immense potential of her creation, the cult and its enigmatic leader forge a powerful alliance, embarking on a transformative mission to liberate society from the shackles of centralized control.

// But this is not a tale without adversity. As the F9 Space Cult grows in prominence, formidable opponents rise from the depths of powerful corporations and governments. They perceive the rise of DeFi and DAOs as an existential threat to their dominion, resolved to halt the cult's progress at any cost.

// Engulfed in a battle of words and actions, the F9 Space Cult and its adversaries wage a monumental war. The cult strategically employs social media platforms, igniting a global movement through impassioned calls for change. Meanwhile, their adversaries, fueled by their vast resources, seek to undermine and discredit them at every turn.

// Still, against all odds, the F9 Space Cult prevails. Its story spreads far and wide, captivating the hearts of countless individuals. The movement transcends the boundaries of a mere cult, blossoming into a vast global network of like-minded visionaries working hand in hand to reshape the world.

// With the gradual fading of centralized systems into obscurity, decentralized finance and autonomous organizations become the new norm. The F9 Space Cult's vision of a fairer and more inclusive world materializes before their very eyes, as power and control are redistributed among the masses.

// In the annals of history, the F9 Space Cult stands as a beacon of courage and audacity, forever etched as the pioneers who dared to challenge the status quo. Their indomitable spirit ushered in a new era of freedom, empowerment, and opportunity for all. The story of the F9 Space Cult serves as a timeless reminder that the power to shape the future rests not in the hands of a select few, but in the collective will of humanity itself.