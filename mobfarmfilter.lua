local recycleList = {
	"fiery",
	"superium",
	"inferium",
	"intermedium",
	"faraday",
	"boron",
	"manasteel"
}

local trashList = {
	"leather_",
	"manaweave",
	"tconstruct",
	"bow",
	"chain"
}

function drainAndInspect()
	turtle.select(1);
	local didSuck = turtle.suck(64);

	if didSuck == false then
		return false;
	end
	
	local data = turtle.getItemDetail(1);
	local name = data.name;
	return name;
end

function isRecycleable(name)
	local found;
	
	for i=1,#trashList do
		found = string.find( name, trashList[i]);

		if found then
			return "trash";
		end
	end

	for i=1,#recycleList do
		found = string.find( name, recycleList[i]);

		if found then
			return "recycle";
		end
	end
	
	return "default"
end

while true do 
	local itemName = drainAndInspect();

	if itemName == false then
		os.sleep(1)
	else
		print(itemName);
		local canRecycle = isRecycleable(itemName);

		if canRecycle == "default" then
			print("storing");
			local hasDropped = turtle.dropUp(64)

			if (hasDropped == false) then
				print("Please empty the fucking chest");
				while turtle.dropUp(64) == false do
					os.sleep(1);
				end
			end
		elseif canRecycle == "recycle" then
			print("recycling");
			local hasDropped = turtle.dropDown(64);

			if (hasDropped == false) then
				print("Please empty the fucking chest");
	
				while turtle.dropDown(64) == false do
					os.sleep(1);
				end
			end
		else
			print("trashing");
			turtle.turnLeft();
			local hasDropped = turtle.drop(64);

			if (hasDropped == false) then
				print("Please empty the fucking chest");	

				while turtle.drop(64) == false do
					os.sleep(1);
				end
			end
			turtle.turnRight();
		end
	end
end
