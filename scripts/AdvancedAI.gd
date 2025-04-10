extends Node

# Neural Network สำหรับระบบ AI
class NeuralNetwork:
    var input_nodes: int
    var hidden_nodes: int
    var output_nodes: int
    var weights_ih: Array
    var weights_ho: Array
    var bias_h: Array
    var bias_o: Array
    var learning_rate: float = 0.1

    func _init(input: int, hidden: int, output: int):
        self.input_nodes = input
        self.hidden_nodes = hidden
        self.output_nodes = output
        
        # กำหนดค่าเริ่มต้นให้ weights และ biases
        self.weights_ih = _create_matrix(hidden, input)
        self.weights_ho = _create_matrix(output, hidden)
        self.bias_h = _create_array(hidden)
        self.bias_o = _create_array(output)

    func predict(input_array: Array) -> Array:
        # Feedforward
        var hidden = _matrix_multiply(self.weights_ih, input_array)
        hidden = _vector_add(hidden, self.bias_h)
        hidden = _sigmoid(hidden)
        
        var outputs = _matrix_multiply(self.weights_ho, hidden)
        outputs = _vector_add(outputs, self.bias_o)
        outputs = _sigmoid(outputs)
        
        return outputs

    func train(input_array: Array, target_array: Array):
        # Feedforward
        var hidden = _matrix_multiply(self.weights_ih, input_array)
        hidden = _vector_add(hidden, self.bias_h)
        hidden = _sigmoid(hidden)
        
        var outputs = _matrix_multiply(self.weights_ho, hidden)
        outputs = _vector_add(outputs, self.bias_o)
        outputs = _sigmoid(outputs)
        
        # Backpropagation
        var output_errors = _vector_subtract(target_array, outputs)
        var gradients = _dsigmoid(outputs)
        gradients = _vector_multiply(gradients, output_errors)
        gradients = _vector_multiply_scalar(gradients, self.learning_rate)
        
        var hidden_T = _transpose(hidden)
        var weight_ho_deltas = _matrix_multiply(gradients, hidden_T)
        
        self.weights_ho = _matrix_add(self.weights_ho, weight_ho_deltas)
        self.bias_o = _vector_add(self.bias_o, gradients)
        
        var who_T = _transpose(self.weights_ho)
        var hidden_errors = _matrix_multiply(who_T, output_errors)
        
        var hidden_gradient = _dsigmoid(hidden)
        hidden_gradient = _vector_multiply(hidden_gradient, hidden_errors)
        hidden_gradient = _vector_multiply_scalar(hidden_gradient, self.learning_rate)
        
        var inputs_T = _transpose(input_array)
        var weight_ih_deltas = _matrix_multiply(hidden_gradient, inputs_T)
        
        self.weights_ih = _matrix_add(self.weights_ih, weight_ih_deltas)
        self.bias_h = _vector_add(self.bias_h, hidden_gradient)

    # Helper functions
    func _sigmoid(x: Array) -> Array:
        var result = []
        for val in x:
            result.append(1.0 / (1.0 + exp(-val)))
        return result

    func _dsigmoid(x: Array) -> Array:
        var result = []
        for val in x:
            result.append(val * (1 - val))
        return result

    func _create_matrix(rows: int, cols: int) -> Array:
        var matrix = []
        for i in range(rows):
            var row = []
            for j in range(cols):
                row.append(randf() * 2 - 1) # Random between -1 and 1
            matrix.append(row)
        return matrix

    func _create_array(size: int) -> Array:
        var arr = []
        for i in range(size):
            arr.append(randf() * 2 - 1) # Random between -1 and 1
        return arr

    func _matrix_multiply(a: Array, b: Array) -> Array:
        var result = []
        for i in range(a.size()):
            var sum = 0.0
            for j in range(b.size()):
                sum += a[i][j] * b[j]
            result.append(sum)
        return result

    func _vector_add(a: Array, b: Array) -> Array:
        var result = []
        for i in range(a.size()):
            result.append(a[i] + b[i])
        return result

    func _vector_subtract(a: Array, b: Array) -> Array:
        var result = []
        for i in range(a.size()):
            result.append(a[i] - b[i])
        return result

    func _vector_multiply(a: Array, b: Array) -> Array:
        var result = []
        for i in range(a.size()):
            result.append(a[i] * b[i])
        return result

    func _vector_multiply_scalar(a: Array, scalar: float) -> Array:
        var result = []
        for val in a:
            result.append(val * scalar)
        return result

    func _matrix_add(a: Array, b: Array) -> Array:
        var result = []
        for i in range(a.size()):
            var row = []
            for j in range(a[i].size()):
                row.append(a[i][j] + b[i][j])
            result.append(row)
        return result

    func _transpose(a: Array) -> Array:
        var result = []
        for i in range(a[0].size()):
            var row = []
            for j in range(a.size()):
                row.append(a[j][i])
            result.append(row)
        return result

# Reinforcement Learning สำหรับ NPC
class RLAgent:
    var q_table: Dictionary
    var actions: Array
    var learning_rate: float = 0.1
    var discount_factor: float = 0.95
    var exploration_rate: float = 0.3
    
    func _init(actions: Array):
        self.actions = actions
        self.q_table = {}
    
    func get_action(state: String) -> String:
        if randf() < exploration_rate or not q_table.has(state):
            return actions[randi() % actions.size()]
        
        var best_action = actions[0]
        var max_value = -INF
        
        for action in actions:
            var key = state + "|" + action
            if q_table.has(key) and q_table[key] > max_value:
                max_value = q_table[key]
                best_action = action
        
        return best_action
    
    func learn(state: String, action: String, reward: float, next_state: String):
        var key = state + "|" + action
        if not q_table.has(key):
            q_table[key] = 0.0
        
        var max_next_value = -INF
        for a in actions:
            var next_key = next_state + "|" + a
            if q_table.has(next_key) and q_table[next_key] > max_next_value:
                max_next_value = q_table[next_key]
        
        if max_next_value == -INF:
            max_next_value = 0.0
        
        q_table[key] = (1 - learning_rate) * q_table[key] + learning_rate * (reward + discount_factor * max_next_value)

# ระบบ Advanced AI
var neural_networks = {}
var rl_agents = {}

func _ready():
    # เริ่มต้นระบบ AI ขั้นสูง
    init_advanced_ai()

func init_advanced_ai():
    # สร้าง Neural Network สำหรับ NPC แต่ละตัว
    var npcs = get_tree().get_nodes_in_group("npc")
    for npc in npcs:
        var nn = NeuralNetwork.new(5, 8, 3) # 5 inputs, 8 hidden, 3 outputs
        neural_networks[npc.get_instance_id()] = nn
    
    # สร้าง RL Agent สำหรับศัตรูแต่ละตัว
    var enemies = get_tree().get_nodes_in_group("enemy")
    for enemy in enemies:
        var actions = ["attack", "chase", "flee", "patrol"]
        var rl_agent = RLAgent.new(actions)
        rl_agents[enemy.get_instance_id()] = rl_agent

func _process(delta):
    # อัพเดทระบบ AI ทุกเฟรม
    update_ai_systems(delta)

func update_ai_systems(delta):
    # อัพเดท Neural Networks
    for id in neural_networks:
        var npc = instance_from_id(id)
        if npc:
            var inputs = [
                npc.global_position.x,
                npc.global_position.y,
                npc.health,
                npc.speed,
                delta
            ]
            var outputs = neural_networks[id].predict(inputs)
            # ใช้ outputs ควบคุม NPC
    
    # อัพเดท RL Agents
    for id in rl_agents:
        var enemy = instance_from_id(id)
        if enemy:
            var state = str(enemy.global_position) + "|" + str(enemy.health)
            var action = rl_agents[id].get_action(state)
            # ดำเนินการตาม action ที่ได้
            match action:
                "attack":
                    enemy.attack()
                "chase":
                    enemy.chase_player()
                "flee":
                    enemy.flee()
                "patrol":
                    enemy.patrol()
            
            # คำนวณ reward และเรียนรู้
            var reward = calculate_reward(enemy, action)
            var next_state = str(enemy.global_position) + "|" + str(enemy.health)
            rl_agents[id].learn(state, action, reward, next_state)

func calculate_reward(enemy, action) -> float:
    # ระบบคำนวณ reward สำหรับ RL
    var reward = 0.0
    
    var player = get_tree().get_nodes_in_group("player")[0]
    var distance = enemy.global_position.distance_to(player.global_position)
    
    match action:
        "attack":
            if distance < 50: # ระยะโจมตี
                reward += 1.0
            else:
                reward -= 0.5
        "chase":
            if distance > 50 and distance < 300: # ระยะไล่ล่า
                reward += 0.7
            else:
                reward -= 0.3
        "flee":
            if enemy.health < 30: # HP ต่ำ
                reward += 1.2
            else:
                reward -= 0.8
        "patrol":
            if distance > 300: # ระยะไกล
                reward += 0.5
            else:
                reward -= 0.2
    
    return reward