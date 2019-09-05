#!/usr/bin/ruby -w
GC.start(full_mark: true, immediate_sweep: true)
require 'ruby2d'

W, H = 640, 480
set width: W, height: H, fps_cap: 100, resizable: true

Array.define_method(:indexes) do |&block|
	i, arr_size = -1, size
	[].tap { |x| x << i if block === at(i) while (i = i.next) < arr_size }
end

def main
	fireworks, pos, sub_particles = [], [], []
	Rectangle.new(width: W, height: H, color: '#FFFFFF', x: 0, y: 0)
	stars = Array.new(H.fdiv(2)) { |i| Square.new(x: rand(W), y: i, size: rand(1 .. 2), color: [rand, rand, rand, 1], opacity: 1 - i.fdiv(H / 1.5)) }

	fps = Text.new(??, font: File.join(__dir__, 'Baumans-Regular.ttf'))
	drag, enable_auto, auto = false, false, 1

	new_fireworks = proc do |x = rand(W), y = rand(H)|
		fireworks.push(Array.new(rand(20 .. 80)) { Circle.new(radius: rand(2 .. 3), color: [rand, rand, rand, 1], x: W / 2, y: H, sectors: 3) })
		pos.push([x, y, false])
	end

	clean = proc do
		Window.clear
		pos.clear
		fireworks.clear
		sub_particles.clear
		Rectangle.new(width: W, height: H, color: '#000000')
		stars.replace(stars.size.times.map { |i| stars.at(i).then { |d| Square.new(x: d.x, y: d.y, size: d.size, color: d.color, opacity: d.opacity, z: d.z) } })
		fps = Text.new(??, font: File.join(__dir__, 'Baumans-Regular.ttf'))
	end

	update do
		new_fireworks.(get(:mouse_x), get(:mouse_y)) if drag
		new_fireworks.(rand(W), rand(H)) if enable_auto && get(:fps) > 20
		stars.sample.z = [-1, 1].sample

		clean.call if fireworks.flatten.size.zero?

		get(:fps).round.tap do |x|
			fps.text = "FPS: #{x}  | Spawned Fireworks: #{fireworks.size} | Particles: #{fireworks.reduce(0) { |x, y| x += y.size } + sub_particles.size }"
			fps.color = x < 16 ? '#FF5555' : x < 30 ? '#5555FF' : x < 46 ? '#FFFF55' : '#55FF55'
		end

		fireworks.indexes(&:empty?).each { |x| pos.delete_at(x) && fireworks.delete_at(x) }

		sub_particles.each_with_index do |x, i|
			x.x, x.y, x.color = x.x + Math.cos(i), x.y + Math.atan(i), [rand, rand, rand, x.opacity - 0.025]
			x.remove && sub_particles.delete(x) if x.opacity < 0
		end

		fireworks.each_with_index do |particles, findex|
			particles[0].tap { |fr| sub_particles.push(Square.new(x: rand(fr.x - 5 .. fr.x + 5), y: fr.y, size: 1, color: [rand, rand, rand, 0.75])) if fr&.radius&.> 1 }
			particles_size = particles.size - 1
			x, y, activated = *pos.at(findex)

			particles.each_with_index do |p, i|
 				unless p.contains?(x, y).|(activated)
					p.x, p.y = p.x - p.x.-(x).fdiv(16), p.y - p.y.-(y).fdiv(16)
				else
					pos[findex][2] ||= true
					p.x, p.y, p.opacity = p.x + Math.cos(i) * i.fdiv(particles_size), p.y + Math.sin(i) * i.fdiv(particles_size), p.opacity - 0.005

					p.radius -= 0.05 unless p.radius < 0.3
					p.y, p.color = p.y + i.fdiv(particles_size), [rand, rand, rand, p.opacity] if p.radius < 1
				end

				p.remove && particles.delete(p) if p.opacity <= 0
			end
		end
	end

	on(:mouse_down) do |e|
		new_fireworks.(e.x, e.y) if e.button.eql?(:left)
		clean.call if e.button.eql?(:middle)
		drag = true if e.button.eql?(:right)
	end

	on(:mouse_up) { drag = false }

	on(:key_down) do |k|
		if k.key.eql?('escape') then close
		elsif k.key.eql?(?c) then clean.call
		elsif k.key.eql?(?a) then enable_auto = (auto += 1).modulo(2).zero?
		elsif k.key.eql?(?s) then Window.screenshot("#{Time.new.strftime("#{File.basename(__FILE__).capitalize}-Screenshot-%H:%M:%S:%N")}.png")
		end
	end

	on(:key_held) do |k|
		new_fireworks.(rand(W), rand(H)) if k.key.eql?(?r)
		new_fireworks.(get(:mouse_x), get(:mouse_y)) if k.key.eql?('space')
	end
end

main
show
